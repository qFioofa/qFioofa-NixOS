{ pkgs, ... }:
{
  home.packages = with pkgs; [
    handy
    wtype
    wl-clipboard
  ];
}
