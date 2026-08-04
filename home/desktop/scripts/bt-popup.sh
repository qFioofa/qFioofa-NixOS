#!/usr/bin/env bash
rofi() { @rofi@ -dmenu -i -theme @popupTheme@ "$@"; }

if [ "$(@bluetoothctl@ show | @awk@ '/Powered:/ {print $2; exit}')" = "yes" ]; then
  toggle="󰂲  Power off"
  @bluetoothctl@ --timeout 4 scan on >/dev/null 2>&1 &
  devices=$(@bluetoothctl@ devices | while read -r _ mac name; do
    if @bluetoothctl@ info "$mac" | grep -q "Connected: yes"; then
      printf '󰂱  %s\n' "$name"
    else
      printf '󰂯  %s\n' "$name"
    fi
  done)
else
  toggle="󰂯  Power on"
  devices=""
fi

chosen=$(printf '%s\n%s' "$toggle" "$devices" | rofi -p "Bluetooth")
[ -z "$chosen" ] && exit 0

case "$chosen" in
  *"Power on")  @bluetoothctl@ power on;  exit 0 ;;
  *"Power off") @bluetoothctl@ power off; exit 0 ;;
esac

# Strip the leading icon + two spaces to recover the device name, then
# resolve it back to a MAC address.
name=${chosen#*  }
mac=$(@bluetoothctl@ devices | grep -F " $name" | head -n1 | @awk@ '{print $2}')
[ -z "$mac" ] && exit 0

if @bluetoothctl@ info "$mac" | grep -q "Connected: yes"; then
  @bluetoothctl@ disconnect "$mac" && @notify@ "Bluetooth" "Disconnected $name"
else
  if @bluetoothctl@ connect "$mac" >/dev/null 2>&1; then
    @notify@ "Bluetooth" "Connected $name"
  else
    @notify@ -u critical "Bluetooth" "Failed to connect $name"
  fi
fi
