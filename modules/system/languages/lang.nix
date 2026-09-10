{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs
    rustc
    scala
    cargo
    go
    zig

    beamPackages.elixir
    beamPackages.erlang
  ];
}
