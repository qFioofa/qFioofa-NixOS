{ pkgs, ... }: {
  xdg.portal = {
    enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];

    config.niri = {
      default                                   = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access"      = [ "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast"  = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot"  = [ "gnome" ];
    };
  };
}
