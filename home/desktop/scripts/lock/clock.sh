#!/usr/bin/env bash
printf '\033[?25l'                       # hide cursor
pw=""; ph=""
while :; do
  h=$(@tmux@ display -p '#{pane_height}' 2>/dev/null); : "${h:=0}"
  w=$(@tmux@ display -p '#{pane_width}'  2>/dev/null); : "${w:=0}"
  if [ "$w" != "$pw" ] || [ "$h" != "$ph" ]; then
    printf '\033[2J'; pw=$w; ph=$h
  fi
  hms=$(@date@ '+%H:%M:%S')
  t=$(printf '%s' "$hms" | @sed@ 's/:/\x1b[90m:\x1b[1;33m/g')
  row=$(( h / 2 + 1 )); [ "$row" -lt 1 ] && row=1
  col=$(( (w - ${#hms}) / 2 + 1 )); [ "$col" -lt 1 ] && col=1
  printf '\033[%d;%dH\033[1;33m%s\033[0m' "$row" "$col" "$t"
  @sleep@ 1
done
