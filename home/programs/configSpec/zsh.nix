{ inputs, pkgs, ... }:
{
  imports = [ inputs.zsh-config.homeManagerModules.default ];

  home.packages = with pkgs; [ zsh starship fzf git ];
}
