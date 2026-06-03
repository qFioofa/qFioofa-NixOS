{ inputs, ... }:
{
  imports = [
    ../default.nix
    ./hardware.nix
    ./user.nix
  ];

  networking.hostName = "qFioofa";

  system.stateVersion = "24.11";
}
