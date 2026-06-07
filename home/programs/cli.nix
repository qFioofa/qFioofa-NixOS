
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
    dust
    jq

    btop
    unzip
    zip
    p7zip

    playerctl
    asciiquarium

    tree
    file
  ];
}
