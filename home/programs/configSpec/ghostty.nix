{ inputs, pkgs, ... }:
{
  imports = [ inputs.ghostty-config.homeManagerModules.default ];

  home.packages = [ pkgs.ghostty ];
}
