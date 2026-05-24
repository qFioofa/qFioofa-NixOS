{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./apps/niri.nix
    ./apps/amnezia-vpn.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "UTC"; # change to your timezone, e.g. "Europe/Moscow"
  i18n.defaultLocale = "en_US.UTF-8";

  # User — change "user" to your username
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
  };

  # Base system packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    htop
  ];

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  system.stateVersion = "24.11";
}
