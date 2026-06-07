
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    curl
    wget
    bat
    fd
    ripgrep
    fzf
    eza
    zoxide
    btop
    dust
    jq
    unzip
    zip
    p7zip
    playerctl
    asciiquarium
  ];
}
