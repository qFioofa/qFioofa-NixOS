{ ... }:
{
  imports = [
    ../../home/programmes/configSpec/zsh.nix
    ../../home/programmes/configSpec/tmux.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";

  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
