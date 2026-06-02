{ inputs, ... }:
{
  imports = [
    ./hardware.nix

    ../../modules/system/boot.nix
    ../../modules/system/locale.nix
    ../../modules/system/networking.nix
    ../../modules/system/audio.nix
    ../../modules/system/users.nix

    ../../modules/desktop/niri.nix
    ../../modules/desktop/login.nix
    ../../modules/desktop/fonts.nix
  ];

  networking.hostName = "nixos";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.qFioofa = import ../../home/default.nix;

  system.stateVersion = "24.11";
}
