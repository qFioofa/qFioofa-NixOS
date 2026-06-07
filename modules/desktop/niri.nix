{ pkgs, ... }:
{
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # niri ships a portals.conf that defaults FileChooser to the gnome backend,
    # which delegates to nautilus. We use nemo, so route the file picker (and
    # everything else) to the gtk backend explicitly — otherwise save/download
    # dialogs in Firefox/Chromium silently never appear.
    config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  security.polkit.enable = true;

  # Allow swaylock to authenticate the user (otherwise the lock can't be unlocked).
  security.pam.services.swaylock = { };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    brightnessctl
    pavucontrol
  ];
}
