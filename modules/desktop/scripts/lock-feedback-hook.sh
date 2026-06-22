#!/usr/bin/env bash
dir="/run/user/$(@id@ -u)"
[ -d "$dir" ] || exit 0
IFS= read -r pw 2>/dev/null || true
len=${#pw}
pw=
printf '%s %s\n' "$(@date@ +%s)" "$len" \
  >> "$dir/lock-feedback" 2>/dev/null || true
exit 0
