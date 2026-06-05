{ pkgs, ... }:
{
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
      size = 12;
    };

    settings = {
      background = {
        path = ../../wallpaper/b-102.jpg;
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;
    };
  };
}
