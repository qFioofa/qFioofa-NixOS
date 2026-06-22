{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    rustc
    cargo
    gcc
    go
    zig
    elixir
    erlang
  ];
}
