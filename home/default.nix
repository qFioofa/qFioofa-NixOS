{ pkgs, ... }:
{
  imports = [
    ./desktop
    ./programmes
  ];

  home.username = "qFioofa";
  home.homeDirectory = "/home/qFioofa";

  xdg.enable = true;
  xdg.systemDirs.data = [
    "/run/current-system/sw/share"
    "/etc/profiles/per-user/qFioofa/share"
  ];

  home.packages = with pkgs; [
    swaybg
    cliphist
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
