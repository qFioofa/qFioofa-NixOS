{ inputs, pkgs, ... }:
{
  # Config (wezterm.lua, themes, events) is sourced from the upstream flake:
  #   github:qFioofa/qFioofa-wezterm -> homeManagerModules.default
  # It recursively links src/ into ~/.config/wezterm. Update with `nix flake update wezterm-config`.
  imports = [ inputs.wezterm-config.homeManagerModules.default ];

  home.packages = [ pkgs.wezterm ];
}
