{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nodejs
    rustc
    scala
    cargo
    go
    zig

    ruby
    rubyPackages.railties

    beamPackages.elixir
    beamPackages.erlang
  ];
}
