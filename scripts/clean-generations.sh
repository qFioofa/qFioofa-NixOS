#!/usr/bin/env bash
# Delete previous Nix generations and reclaim disk space.
#
# Removes old generations of the system profile and the calling user's profile
# (and the home-manager profile if a standalone CLI is present), then runs the
# garbage collector. The current / booted generation is always kept. Finally it
# rewrites the bootloader entries so the deleted system generations disappear
# from the boot menu.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -d, --days N   Keep generations newer than N days (default: delete all but current)
  -n, --dry-run  Print the commands instead of running them
  -h, --help     Show this help
EOF
}

DAYS=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--days)   DAYS="${2:?--days needs a number}"; shift 2 ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '+ %s\n' "$*"
  else
    "$@"
  fi
}

SYSTEM_PROFILE=/nix/var/nix/profiles/system

if [[ -n "$DAYS" ]]; then
  AGE="${DAYS}d"
  echo ">> Deleting generations older than ${AGE}..."
  run sudo nix-env --profile "$SYSTEM_PROFILE" --delete-generations "$AGE"
  run nix-env --delete-generations "$AGE"
  if command -v home-manager >/dev/null 2>&1; then
    run home-manager expire-generations "-${DAYS} days"
  fi
  echo ">> Collecting garbage older than ${AGE}..."
  run sudo nix-collect-garbage --delete-older-than "$AGE"
else
  echo ">> Deleting ALL old generations (keeping current)..."
  run sudo nix-env --profile "$SYSTEM_PROFILE" --delete-generations old
  run nix-env --delete-generations old
  if command -v home-manager >/dev/null 2>&1; then
    run home-manager expire-generations 0
  fi
  echo ">> Collecting garbage..."
  run sudo nix-collect-garbage -d
fi

echo ">> Rewriting bootloader entries..."
run sudo "$SYSTEM_PROFILE"/bin/switch-to-configuration boot

echo ">> Done."
df -h /nix/store | tail -1
