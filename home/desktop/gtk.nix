{ pkgs, ... }:
{
  # libadwaita / GTK4 apps (satty, gnome apps) ignore gtk-application-prefer-dark-theme
  # and follow this gsettings key instead. Without it they render bright.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  gtk = {
    enable = true;
    # Shared icon theme so GTK apps and the rofi launcher (icon-theme in
    # launcher.nix) draw from the same set.
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Nordzy-catppuccin-latte-peach";
      package = pkgs.nordzy-cursor-theme;
    };
    # Render GTK apps (Nemo, etc.) dark to match the desktop instead of the
    # default light Adwaita.
    gtk3.extraConfig = {
      gtk-enable-primary-paste = false;
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-enable-primary-paste = false;
      gtk-application-prefer-dark-theme = true;
    };
  };
}
