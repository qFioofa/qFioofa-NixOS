{ inputs, pkgs, ... }:
{
  # Config (settings, theme, shader) is sourced from the upstream flake:
  #   github:qFioofa/qFioofa-Ghostty -> homeManagerModules.default
  # It recursively links src/ into ~/.config/ghostty. Update with `nix flake update ghostty-config`.
  imports = [ inputs.ghostty-config.homeManagerModules.default ];

  home.packages = [ pkgs.ghostty ];
}
