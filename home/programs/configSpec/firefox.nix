{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    web-ext  # Пакет для управления расширениями Firefox
  ];

  home.sessionVariables.BROWSER = "firefox";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
    };
  };
}
