{ pkgs, ... }:
{
  home.packages = with pkgs; [ firefox ];

  home.sessionVariables.BROWSER = "firefox";

  # Make Firefox the default browser for opening links / HTML files
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
