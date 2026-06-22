#!/usr/bin/env bash
# Now-playing indicator. Always prints valid JSON so the capsule renders
# something graceful ("Idle") when no player is active.
esc() { printf '%s' "$1" | @sed@ 's/\\/\\\\/g; s/"/\\"/g'; }

status=$(@playerctl@ status 2>/dev/null)
if [ -z "$status" ]; then
  printf '{"text":"󰝛  Idle · no sound","tooltip":"Nothing is playing","class":"empty"}\n'
  exit 0
fi

title=$(@playerctl@ metadata title 2>/dev/null)
artist=$(@playerctl@ metadata artist 2>/dev/null)
[ -z "$title" ] && title="Unknown"

if [ ${#title} -gt 28 ]; then
  title=$(printf '%s' "$title" | @cut@ -c1-27)…
fi

case "$status" in
  Playing) icon="󰎆" ; cls="playing" ;;
  Paused)  icon="󰏤" ; cls="paused"  ;;
  *)       icon="󰎈" ; cls="stopped" ;;
esac

printf '{"text":"%s  %s","tooltip":"%s","class":"%s"}\n' \
  "$icon" "$(esc "$title")" "$(esc "$artist")" "$cls"
