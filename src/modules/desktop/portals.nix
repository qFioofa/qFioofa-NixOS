{ pkgs, ... }: {
  # ── XDG desktop portals ───────────────────────────────────────────────
  # Portals let sandboxed/Wayland apps request host services. The GNOME
  # portal provides ScreenCast/Screenshot (screen sharing in OBS, browsers,
  # Zoom via PipeWire); the GTK portal handles file pickers and notifications.
  # `config.niri` routes each interface to the right backend.
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
