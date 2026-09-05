{ ... }:
{
  imports = [
    # System-level niri stack (systemd units, portals, PAM, gvfs/udisks). The
    # user-level niri window-manager config lives in home/desktop/niri.nix —
    # these are deliberately separate files with the same name segmented by
    # their parent level (modules/ = OS, home/ = per-user dotfiles).
    ./compositor.nix
    ./login.nix
    ./fonts.nix
  ];
}
