#!/usr/bin/env bash
h=$(@tmux@ display -p '#{pane_height}' 2>/dev/null)
w=$(@tmux@ display -p '#{pane_width}'  2>/dev/null)
: "${h:=0}" "${w:=0}"
content=$(@cat@)
nlines=$(printf '%s\n' "$content" | @wc@ -l)
width=$(printf '%s\n' "$content" \
  | @sed@ 's/\x1b\[[0-9;]*m//g' \
  | @awk@ '{ if (length > m) m = length } END { print m + 0 }')
top=$(( (h - nlines) / 2 )); [ "$top" -lt 0 ] && top=0
left=$(( (w - width) / 2 )); [ "$left" -lt 0 ] && left=0
pad=$(printf '%*s' "$left" "")
printf '\033[H\033[2J'
i=0; while [ "$i" -lt "$top" ]; do printf '\n'; i=$(( i + 1 )); done
printf '%s\n' "$content" | while IFS= read -r line; do
  printf '%s%s\n' "$pad" "$line"
done
