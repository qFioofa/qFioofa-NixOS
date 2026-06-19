{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # python3 lives in ./dataScience.nix (bundled with the Jupyter / DS stack)
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
