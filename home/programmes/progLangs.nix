{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python3
    nodejs
    rustc
    cargo
    gcc
    clang
    go
  ];
}
