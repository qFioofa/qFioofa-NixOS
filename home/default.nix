{ pkgs, ... }:
{
  imports = [
    ./niri.nix
    ./waybar.nix
    ./terminal.nix
    ./launcher.nix
    ./notifications.nix
  ];

  home.username = "qFioofa";
  home.homeDirectory = "/home/qFioofa";

  home.packages = with pkgs; [
    swaybg
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
