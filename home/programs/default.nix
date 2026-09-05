{ ... }:
# Per-user programs. `configSpec/` holds reusable feature-modules that other
# users (e.g. root) can pull in wholesale — see hosts/root/default.nix.
{
  imports = [
    ./terminal.nix
    ./apps.nix
    ./office.nix
    ./dataScience.nix
    ./configSpec
    ./cli.nix
    ./ai.nix
    ./plantuml.nix
    ./lite-xl.nix
  ];
}
