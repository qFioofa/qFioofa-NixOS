#!/usr/bin/env bash

FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME="${1:-nixos}"

echo "Building NixOS configuration: $HOSTNAME"
sudo nixos-rebuild switch --flake "$FLAKE_DIR#$HOSTNAME"
