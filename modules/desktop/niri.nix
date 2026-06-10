{ pkgs, ... }:
{
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    # niri ships a portals.conf that defaults FileChooser to the gnome backend,
    # which delegates to nautilus. We use nemo, so route the file picker (and
    # everything else) to the gtk backend explicitly — otherwise save/download
    # dialogs in Firefox/Chromium silently never appear.
    #
    # ScreenCast/ScreenShot, however, are *not* implemented by the gtk backend.
    # niri's screen sharing is served by the gnome backend, so route those two
    # interfaces to gnome explicitly — otherwise the screen-share picker never
    # appears in Firefox/Chromium and sharing silently fails.
    config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.ScreenShot" = [ "gnome" ];
    };
  };

  security.polkit.enable = true;

  # Allow the lock screen to authenticate the user (otherwise it can't be
  # unlocked). swaylock-plugin calls pam_start("swaylock-plugin", ...), so the
  # PAM service must be named to match the binary — a plain "swaylock" service
  # is never consulted and PAM falls through to /etc/pam.d/other, which denies
  # every password (correct ones included). We define both names so either
  # binary works.
  security.pam.services.swaylock = { };
  security.pam.services.swaylock-plugin = { };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    brightnessctl
    pavucontrol
  ];
}
