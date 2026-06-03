
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    curl
    wget
    bat
  ];
}
