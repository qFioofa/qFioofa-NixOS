#!/usr/bin/env bash
# Rofi window switcher for niri. Lists every open window ("app · title"),
# filterable by typing, and raises/focuses the chosen one. The window id is
# kept in a parallel list and recovered from rofi's selected index (-format i)
# so it never has to be shown to the user.
data=$(niri msg --json windows 2>/dev/null)
[ -z "$data" ] && exit 0

ids=$(printf '%s' "$data" | @jq@ -r '.[].id')
[ -z "$ids" ] && exit 0

# Emit one rofi row per window as "app · title", tagged with the app_id as
# its icon name (rofi resolves it against the GTK icon theme via -show-icons).
# jq can't emit raw NUL/US bytes, so the row metadata is assembled by printf:
#   <display>\0icon\x1f<icon-name>
chosen=$(printf '%s' "$data" \
  | @jq@ -r '.[] | "\(.app_id // "?")\t\(.title // "")"' \
  | while IFS="$(printf '\t')" read -r app title; do
      printf '%s  ·  %s\0icon\037%s\n' "$app" "$title" "$app"
    done \
  | @rofi@ -dmenu -i -p "Windows" -theme @switcherTheme@ \
      -show-icons -no-custom -format i)
[ -z "$chosen" ] && exit 0

id=$(printf '%s' "$ids" | @sed@ -n "$((chosen + 1))p")
[ -z "$id" ] && exit 0

niri msg action focus-window --id "$id"
