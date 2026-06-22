#!/usr/bin/env bash
dir=@wallpaperDir@
wallpaper=$(@find@ "$dir" \
  -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
  | @shuf@ -n 1)
exec @swaybg@ -i "$wallpaper" -m fill
