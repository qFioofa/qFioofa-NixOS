{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs
    rustc
    cargo
    go
    zig
    elixir
    erlang
  ];
}
