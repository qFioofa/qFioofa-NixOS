{ pkgs, ... }:
{
  gtk = {
    enable = true;
    # Shared icon theme so GTK apps and the rofi launcher (icon-theme in
    # launcher.nix) draw from the same set.
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig.gtk-enable-primary-paste = false;
    gtk4.extraConfig.gtk-enable-primary-paste = false;
  };
}
