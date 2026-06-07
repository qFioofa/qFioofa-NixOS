{ pkgs, ... }:
{
  home.packages = with pkgs; [
    telegram-desktop
    vlc
    chromium
    rocketchat-desktop
    nemo
    networkmanagerapplet

    discord
    zoom-us
    gimp
  ];
}
