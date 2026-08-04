{ inputs, ... }:
{
  imports = [
    ../default.nix
    ./hardware.nix
    ./user.nix
  ];

  networking.hostName = "nixos";

  system.stateVersion = "24.11";
}
