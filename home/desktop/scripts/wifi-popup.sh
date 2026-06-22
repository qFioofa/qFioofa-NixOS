#!/usr/bin/env bash
rofi() { @rofi@ -dmenu -i -theme @popupTheme@ "$@"; }

if [ "$(@nmcli@ -t radio wifi)" = "enabled" ]; then
  toggle="󰖪  Disable Wi-Fi"
  @nmcli@ device wifi rescan >/dev/null 2>&1
  networks=$(@nmcli@ --terse --fields SSID,SIGNAL device wifi list \
    | @awk@ -F: '$1 != "" { if (!seen[$1]++) printf "󰖩  %s  ·  %s%%\n", $1, $2 }')
else
  toggle="󰖩  Enable Wi-Fi"
  networks=""
fi

chosen=$(printf '%s\n%s' "$toggle" "$networks" | rofi -p "Wi-Fi")
[ -z "$chosen" ] && exit 0

case "$chosen" in
  *"Enable Wi-Fi")  @nmcli@ radio wifi on;  exit 0 ;;
  *"Disable Wi-Fi") @nmcli@ radio wifi off; exit 0 ;;
esac

# Strip the leading icon and the trailing "  ·  <signal>%".
ssid=${chosen#*  }
ssid=${ssid%%  ·  *}

if @nmcli@ -t -f NAME connection show | grep -Fxq "$ssid"; then
  @nmcli@ connection up id "$ssid" \
    && @notify@ "Wi-Fi" "Connected to $ssid"
elif @nmcli@ device wifi connect "$ssid" >/dev/null 2>&1; then
  @notify@ "Wi-Fi" "Connected to $ssid"
else
  pass=$(rofi -password -p "Password for $ssid" < /dev/null)
  [ -z "$pass" ] && exit 0
  if @nmcli@ device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
    @notify@ "Wi-Fi" "Connected to $ssid"
  else
    @notify@ -u critical "Wi-Fi" "Failed to connect to $ssid"
  fi
fi
