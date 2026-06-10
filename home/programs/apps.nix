{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vlc
    nemo
    chromium
    telegram-desktop
    rocketchat-desktop
    networkmanagerapplet

    gimp
    discord
    zoom-us

    virtualbox
  ];
}
