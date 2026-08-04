#!/usr/bin/env bash
# Pick a keyboard layout from those configured in niri. Switches by stepping
# `switch-layout next` so it works regardless of niri's index-arg support.
data=$(niri msg --json keyboard-layouts 2>/dev/null)
[ -z "$data" ] && exit 0

cur=$(printf '%s' "$data" | @jq@ -r '.current_idx')
count=$(printf '%s' "$data" | @jq@ -r '.names | length')

chosen=$(printf '%s' "$data" \
  | @jq@ -r '.names[]' \
  | @rofi@ -dmenu -i -p "Layout" -theme @layoutTheme@ -no-custom -format i)
[ -z "$chosen" ] && exit 0

steps=$(( (chosen - cur + count) % count ))
while [ "$steps" -gt 0 ]; do
  niri msg action switch-layout next
  steps=$(( steps - 1 ))
done
