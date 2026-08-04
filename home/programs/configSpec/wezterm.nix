{ inputs, pkgs, ... }:
{
  imports = [ inputs.wezterm-config.homeManagerModules.default ];

  home.packages = [ pkgs.wezterm ];
}
