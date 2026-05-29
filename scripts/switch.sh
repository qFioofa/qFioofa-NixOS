#!/usr/bin/env bash

mkdir -p logs
log="logs/switch-$(date +%Y-%m-%dT%H-%M-%S).log"
exec > >(tee -a "$log") 2>&1

echo ":: writing log to $log"
echo ":: nixos-rebuild switch…"
sudo nixos-rebuild switch --flake .#nixos
