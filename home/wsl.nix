{ homeConfigSpec, ... }:
# Headless WSL user profile: terminal/dev tooling only. Mirrors the non-GUI
# half of home/default.nix and deliberately excludes home/desktop, the GUI apps
# (apps.nix) and the gui.nix feature set (firefox/media/ghostty/wezterm/office).
{
  imports = [
    (homeConfigSpec + "/terminal.nix")
    ./programs/cli.nix
    ./programs/ai.nix
    ./programs/dataScience.nix
  ];

  home.username = "qFioofa";
  home.homeDirectory = "/home/qFioofa";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
