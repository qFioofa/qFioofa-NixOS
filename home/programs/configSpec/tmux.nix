{ inputs, pkgs, ... }:
{
  imports = [ inputs.tmux-config.homeManagerModules.default ];

  home.packages = with pkgs; [ tmux git fzf ];
}
