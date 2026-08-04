#!/usr/bin/env bash
# item COLOR ICON LABEL — accent-coloured icon per action so the menu isn't
# one flat colour (Shutdown/Reboot lean on the warning/danger hues).
item() { printf '<span color="%s" weight="bold">%s</span>   %s\n' "$1" "$2" "$3"; }

chosen=$( { \
  item "@tide@"    "󰍁" "Lock"; \
  item "@amber@"   "󰍃" "Logout"; \
  item "@violet@"  "󰒲" "Suspend"; \
  item "@warning@" "󰜉" "Reboot"; \
  item "@error@"   "󰐥" "Shutdown"; \
  } | @rofi@ -dmenu -i -markup-rows -p "Power" \
      -theme @menuTheme@ \
      -no-custom -format s)

case "$chosen" in
  *Lock*)     lock ;;
  *Logout*)   niri msg action quit --skip-confirmation ;;
  *Suspend*)  systemctl suspend ;;
  *Reboot*)   systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
esac
