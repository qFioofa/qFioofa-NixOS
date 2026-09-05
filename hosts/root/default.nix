{ homeConfigSpec, ... }:
{
  # Shared config-as-modules passed in via specialArgs (see flake.nix). Root
  # only gets the terminal-adjacent feature modules, not the full user stack.
  imports = [
    (homeConfigSpec + "/zsh.nix")
    (homeConfigSpec + "/tmux.nix")
  ];

  home.username = "root";
  home.homeDirectory = "/root";

  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
