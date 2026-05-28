{ ... }: {
  imports = [
    ./hardware.nix
    ../modules/system/boot.nix
    ../modules/system/locale.nix
    ../modules/system/networking.nix
    ../modules/system/audio.nix
    ../modules/system/bluetooth.nix
    ../modules/system/users.nix
    ../modules/desktop/niri.nix
    ../modules/desktop/fonts.nix
    ../modules/desktop/portals.nix
    ../modules/apps/default.nix
  ];

  networking.hostName = "nixos";
  system.stateVersion = "24.11";

  services.displayManager.sddm.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoLogin.enable = true;
  services.xserver.displayManager.sddm.autoLogin.user = "qFioofa";
  services.xserver.desktopManager.plasma5.enable = false;
  services.xserver.desktopManager.gnome.enable = false;
}
