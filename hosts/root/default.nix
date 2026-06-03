{ ... }:
{
  imports = [
    ../../home/programs/configSpec/zsh.nix
    ../../home/programs/configSpec/tmux.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";

  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
