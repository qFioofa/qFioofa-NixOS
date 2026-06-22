#!/usr/bin/env bash
w=$(@tmux@ display -p '#{pane_width}' 2>/dev/null); : "${w:=0}"
content=$(@cat@)
width=$(printf '%s\n' "$content" \
  | @sed@ 's/\x1b\[[0-9;]*m//g' \
  | @awk@ '{ if (length > m) m = length } END { print m + 0 }')
left=$(( (w - width) / 2 )); [ "$left" -lt 0 ] && left=0
pad=$(printf '%*s' "$left" "")
printf '\033[H\033[2J'
printf '%s\n' "$content" | while IFS= read -r line; do
  printf '%s%s\n' "$pad" "$line"
done
