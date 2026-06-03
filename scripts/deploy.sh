#!/usr/bin/env bash
set -euo pipefail

FLAKE="${FLAKE:-flake.nix}"
HOST="${HOST:-$(hostname)}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  s, switch   Apply config immediately
  b, boot     Apply on next reboot
  t, test     Apply temporarily (resets after reboot)
  u, update   Update flake inputs
  r, rollback Revert to previous generation
  g, gc       Clean old generations & run garbage collector
  h, help     Show this help
EOF
}

[[ $# -eq 0 ]] && { usage; exit 0; }

case "$1" in
  s|switch)   sudo nixos-rebuild switch --flake "$FLAKE#$HOST" ;;
  b|boot)     sudo nixos-rebuild boot   --flake "$FLAKE#$HOST" ;;
  t|test)     sudo nixos-rebuild test   --flake "$FLAKE#$HOST" ;;
  u|update)   nix flake update --flake "$FLAKE" ;;
  r|rollback) sudo nixos-rebuild switch --rollback ;;
  g|gc)       sudo nix-collect-garbage -d ;;
  h|help)     usage ;;
  *)          echo "Unknown command: $1"; usage; exit 1 ;;
esac
