{ inputs, pkgs, ... }:
{
  # Config is sourced from the upstream flake:
  #   github:qFioofa/qFioofa-tmux -> homeManagerModules.default
  # It recursively links src/ into ~/.config/tmux. Update with `nix flake update tmux-config`.
  imports = [ inputs.tmux-config.homeManagerModules.default ];

  # Tools the config / tpm plugins expect on PATH:
  #   git -> tpm clones plugins   fzf -> tmux-fzf-url, sessionx, floax
  home.packages = with pkgs; [ tmux git fzf ];
}
