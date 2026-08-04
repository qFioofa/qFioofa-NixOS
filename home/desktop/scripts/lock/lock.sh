#!/usr/bin/env bash
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/swaylock.lock"
@flock@ -n 9 || exit 0

: > "/run/user/$(@id@ -u)/lock-feedback" 2>/dev/null || true

exec @swaylock@ \
  -f -k -F -e \
  --grace 2 --pointer-hysteresis 25 \
  --font "@font@" \
  --indicator-radius 0 --indicator-thickness 0 \
  @swaylockColors@ \
  --command-each "@lockBackground@"
