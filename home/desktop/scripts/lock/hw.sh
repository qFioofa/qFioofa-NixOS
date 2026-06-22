#!/usr/bin/env bash
# wpctl's default-sink id is the DEFAULT_AUDIO_SINK token wrapped in at-signs;
# assemble it from parts so the build-time @-substitution leaves it intact.
sink='@'DEFAULT_AUDIO_SINK'@'
while :; do
 {
  v=$(@wpctl@ get-volume "$sink" 2>/dev/null)
  if [ -n "$v" ]; then
    vp=$(printf '%s' "$v" | @awk@ '{print int($2*100+0.5)}'); : "${vp:=0}"
    if printf '%s' "$v" | @grep@ -q MUTED; then
      printf '\033[90m󰝟\033[0m  %s \033[90m%s%%\033[0m\n' "$(@bar@ "$vp" 7 90)" "$vp"
    else
      printf '\033[36m󰕾\033[0m  %s \033[90m%s%%\033[0m\n' "$(@bar@ "$vp" 7 36)" "$vp"
    fi
  fi
  bp=$(@brightnessctl@ -m 2>/dev/null | @awk@ -F, '{gsub(/%/,"",$4);print $4+0}')
  [ -n "$bp" ] && printf '\033[93m󰃟\033[0m  %s \033[90m%s%%\033[0m\n' "$(@bar@ "$bp" 7 93)" "$bp"
 } | @centerTop@
 @sleep@ 5
done
