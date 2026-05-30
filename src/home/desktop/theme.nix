{ pkgs, ... }: {
  # ── Cursor, GTK & Qt theming ──────────────────────────────────────────
  # Two reasons this exists:
  #   1. Wayland needs an explicit cursor theme — without one niri/apps fall
  #      back to a tiny or invisible X11 cursor. home.pointerCursor installs the
  #      theme, points GTK/X11 at it and exports XCURSOR_THEME/SIZE so every
  #      Wayland client (and niri itself) picks it up.
  #   2. GTK and Qt default to a light theme, so GUI helpers (pavucontrol,
  #      blueman, nm-connection-editor, file pickers) would look out of place
  #      against the dark yugen-ash rice. adw-gtk3-dark + Papirus-Dark unify
  #      them; qt.platformTheme = gtk3 makes Qt apps follow the GTK settings.
  home.pointerCursor = {
    package    = pkgs.bibata-cursors;
    name       = "Bibata-Modern-Classic";
    size       = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name    = "adw-gtk3-dark";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name    = "Papirus-Dark";
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  qt = {
    enable             = true;
    platformTheme.name = "gtk3";
  };
}
