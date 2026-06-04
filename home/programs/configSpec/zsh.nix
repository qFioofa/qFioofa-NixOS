{ inputs, pkgs, ... }:
{
  # Config (.zshrc, plugins, starship.toml) is sourced from the upstream flake:
  #   github:qFioofa/qFioofa-zsh -> homeManagerModules.default
  # It links src/ into ~/.config/zsh and writes ~/.zshenv (ZDOTDIR) so zsh loads it.
  # Update with `nix flake update zsh-config`.
  imports = [ inputs.zsh-config.homeManagerModules.default ];

  # Tools the .zshrc expects on PATH:
  #   starship -> `eval "$(starship init zsh)"`   fzf -> `eval "$(fzf --zsh)"`
  #   git      -> zinit clones plugins at first launch
  home.packages = with pkgs; [ zsh starship fzf git ];
}
