#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs
log="logs/switch-$(date +%Y-%m-%dT%H-%M-%S).log"
exec > >(tee -a "$log") 2>&1

# home-manager uses backupFileExtension = "backup". If a *.backup already exists
# from a previous run, activation ABORTS and silently leaves the OLD config live
# (looks like "config didn't load" / "wallpaper not showing"). Clear the known
# managed dotfiles' stale backups first so activation can always proceed.
echo ":: clearing stale home-manager backups…"
rm -f \
  "$HOME/.config/niri/config.kdl.backup" \
  "$HOME/.config/ghostty/config.backup" \
  "$HOME/.config/alacritty/alacritty.toml.backup" \
  "$HOME/.config/foot/foot.ini.backup" \
  "$HOME/.config/wezterm/wezterm.lua.backup"

echo ":: writing log to $log"
echo ":: nixos-rebuild switch…"
sudo nixos-rebuild switch --flake .#nixos
