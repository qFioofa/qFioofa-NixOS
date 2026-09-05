{ ... }:
# Per-user desktop UI: compositor config + the shells around it (bar, launcher,
# notifications, lock, power menu). OS-level desktop plumbing lives in
# modules/desktop/ — that split is what keeps this layer pure user config.
{
  imports = [
    ./niri.nix
    ./clipboard.nix
    ./gtk.nix
    ./waybar.nix
    ./calendar.nix
    ./launcher.nix
    ./notifications.nix
    ./powermenu.nix
    ./popups.nix
    ./switcher.nix
    ./help.nix
    ./lock.nix
    ./services.nix
  ];
}
