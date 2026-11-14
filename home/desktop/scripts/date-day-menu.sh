#!/usr/bin/env bash
DATE=@date@
ROFI="@rofi@ -theme @calTheme@"
DATE_TOOLS=@dateTools@
WLCOPY=@wlcopy@
NOTIFY=@notify@

d="${1:-}"
[ -z "$d" ] && exit 0

norm=$($DATE -d "$d" '+%Y-%m-%d' 2>/dev/null)
[ -z "$norm" ] && exit 1

esc() { printf '%s' "$1" | @sed@ 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
item() { printf '<span color="%s" weight="bold">%s</span>   %s\n' "$1" "$2" "$3"; }

mesg=$(esc "$($DATE -d "$norm" '+%A, %d %B %Y · ISO week %V')")

choice=$( { \
  item "@primary@" "󰃭" "Details"; \
  item "@tide@"    "󰆏" "Copy date"; \
  item "@violet@"  "󱢖" "Days between"; \
  item "@amber@"   "󰔠" "Add / subtract"; \
  item "@coral@"   "󰥔" "Countdown"; \
  item "@fgMuted@" "󰁍" "Back"; \
} | $ROFI -dmenu -i -markup-rows -p "$norm" -mesg "<tt>$mesg</tt>" -markup -no-custom -format s )

case "$choice" in
  *Details*)    exec "$DATE_TOOLS" details "$norm" ;;
  *Copy*)       printf '%s' "$norm" | "$WLCOPY"; "$NOTIFY" "Calendar" "Copied $norm" 2>/dev/null || true ;;
  *between*)    exec "$DATE_TOOLS" between "$norm" ;;
  *subtract*)   exec "$DATE_TOOLS" shift "$norm" ;;
  *Countdown*)  exec "$DATE_TOOLS" countdown "$norm" ;;
  *)            exit 0 ;;
esac
