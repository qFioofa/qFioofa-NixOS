{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs
    rustc
    cargo
    go
    zig
    beamPackages.elixir
    beamPackages.erlang
  ];
}
