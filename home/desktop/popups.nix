{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg bgSurface fg fgDim fgMuted primary;

  rofi = "${pkgs.rofi}/bin/rofi";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
  awk = "${pkgs.gawk}/bin/awk";
  jq = "${pkgs.jq}/bin/jq";
  notify = "${pkgs.libnotify}/bin/notify-send";

  # Shared theme: a small popup anchored to the top-right corner, just under
  # the bar, so it appears right next to the network/bluetooth icons.
  popupTheme = pkgs.writeText "popup.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      background-color: transparent;
      text-color:       @fg;
    }
    window {
      width:         320px;
      border:        2px;
      border-color:  @accent;
      border-radius: 12px;
      background-color: @bg;
      location: north east;
      anchor:   north east;
      x-offset: -8px;
      y-offset: 48px;
    }
    mainbox {
      padding: 12px;
      spacing: 8px;
      background-color: transparent;
    }
    inputbar {
      spacing: 8px;
      padding: 8px 12px;
      border-radius: 8px;
      background-color: @bg-surface;
      children: [ prompt, entry ];
    }
    prompt { text-color: @accent; }
    entry {
      placeholder: "Search...";
      placeholder-color: @fg-muted;
      text-color: @fg;
    }
    listview {
      lines:    8;
      spacing:  4px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding: 8px 12px;
      spacing: 8px;
      border-radius: 8px;
      background-color: transparent;
      text-color: @fg-dim;
    }
    element selected {
      background-color: @bg-surface;
      text-color: @accent;
    }
    element-text { text-color: inherit; vertical-align: 0.5; }
  '';

  # Same look as popupTheme, but anchored top-left under the language module.
  layoutTheme = pkgs.writeText "layout-popup.rasi" ''
    * {
      bg:         ${bg};
      bg-surface: ${bgSurface};
      fg:         ${fg};
      fg-dim:     ${fgDim};
      fg-muted:   ${fgMuted};
      accent:     ${primary};
      background-color: transparent;
      text-color:       @fg;
    }
    window {
      width:         220px;
      border:        2px;
      border-color:  @accent;
      border-radius: 12px;
      background-color: @bg;
      location: north west;
      anchor:   north west;
      x-offset: 8px;
      y-offset: 48px;
    }
    mainbox {
      padding: 12px;
      spacing: 8px;
      background-color: transparent;
    }
    inputbar { enabled: false; }
    listview {
      lines:    4;
      spacing:  4px;
      scrollbar: false;
      background-color: transparent;
    }
    element {
      padding: 8px 12px;
      spacing: 8px;
      border-radius: 8px;
      background-color: transparent;
      text-color: @fg-dim;
    }
    element selected {
      background-color: @bg-surface;
      text-color: @accent;
    }
    element-text { text-color: inherit; vertical-align: 0.5; }
  '';

  # Pick a keyboard layout from those configured in niri. Switches by stepping
  # `switch-layout next` so it works regardless of niri's index-arg support.
  layoutPopup = pkgs.writeShellScriptBin "layout-popup" ''
    data=$(niri msg --json keyboard-layouts 2>/dev/null)
    [ -z "$data" ] && exit 0

    cur=$(printf '%s' "$data" | ${jq} -r '.current_idx')
    count=$(printf '%s' "$data" | ${jq} -r '.names | length')

    chosen=$(printf '%s' "$data" \
      | ${jq} -r '.names[]' \
      | ${rofi} -dmenu -i -p "Layout" -theme ${layoutTheme} -no-custom -format i)
    [ -z "$chosen" ] && exit 0

    steps=$(( (chosen - cur + count) % count ))
    while [ "$steps" -gt 0 ]; do
      niri msg action switch-layout next
      steps=$(( steps - 1 ))
    done
  '';

  wifiPopup = pkgs.writeShellScriptBin "wifi-popup" ''
    rofi() { ${rofi} -dmenu -i -theme ${popupTheme} "$@"; }

    if [ "$(${nmcli} -t radio wifi)" = "enabled" ]; then
      toggle="󰖪  Disable Wi-Fi"
      ${nmcli} device wifi rescan >/dev/null 2>&1
      networks=$(${nmcli} --terse --fields SSID,SIGNAL device wifi list \
        | ${awk} -F: '$1 != "" { if (!seen[$1]++) printf "󰖩  %s  ·  %s%%\n", $1, $2 }')
    else
      toggle="󰖩  Enable Wi-Fi"
      networks=""
    fi

    chosen=$(printf '%s\n%s' "$toggle" "$networks" | rofi -p "Wi-Fi")
    [ -z "$chosen" ] && exit 0

    case "$chosen" in
      *"Enable Wi-Fi")  ${nmcli} radio wifi on;  exit 0 ;;
      *"Disable Wi-Fi") ${nmcli} radio wifi off; exit 0 ;;
    esac

    # Strip the leading icon and the trailing "  ·  <signal>%".
    ssid=''${chosen#*  }
    ssid=''${ssid%%  ·  *}

    if ${nmcli} -t -f NAME connection show | grep -Fxq "$ssid"; then
      ${nmcli} connection up id "$ssid" \
        && ${notify} "Wi-Fi" "Connected to $ssid"
    elif ${nmcli} device wifi connect "$ssid" >/dev/null 2>&1; then
      ${notify} "Wi-Fi" "Connected to $ssid"
    else
      pass=$(rofi -password -p "Password for $ssid" < /dev/null)
      [ -z "$pass" ] && exit 0
      if ${nmcli} device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        ${notify} "Wi-Fi" "Connected to $ssid"
      else
        ${notify} -u critical "Wi-Fi" "Failed to connect to $ssid"
      fi
    fi
  '';

  btPopup = pkgs.writeShellScriptBin "bt-popup" ''
    rofi() { ${rofi} -dmenu -i -theme ${popupTheme} "$@"; }

    if [ "$(${bluetoothctl} show | ${awk} '/Powered:/ {print $2; exit}')" = "yes" ]; then
      toggle="󰂲  Power off"
      ${bluetoothctl} --timeout 4 scan on >/dev/null 2>&1 &
      devices=$(${bluetoothctl} devices | while read -r _ mac name; do
        if ${bluetoothctl} info "$mac" | grep -q "Connected: yes"; then
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
      *"Power on")  ${bluetoothctl} power on;  exit 0 ;;
      *"Power off") ${bluetoothctl} power off; exit 0 ;;
    esac

    # Strip the leading icon + two spaces to recover the device name, then
    # resolve it back to a MAC address.
    name=''${chosen#*  }
    mac=$(${bluetoothctl} devices | grep -F " $name" | head -n1 | ${awk} '{print $2}')
    [ -z "$mac" ] && exit 0

    if ${bluetoothctl} info "$mac" | grep -q "Connected: yes"; then
      ${bluetoothctl} disconnect "$mac" && ${notify} "Bluetooth" "Disconnected $name"
    else
      if ${bluetoothctl} connect "$mac" >/dev/null 2>&1; then
        ${notify} "Bluetooth" "Connected $name"
      else
        ${notify} -u critical "Bluetooth" "Failed to connect $name"
      fi
    fi
  '';
in
{
  home.packages = [ wifiPopup btPopup layoutPopup ];
}
