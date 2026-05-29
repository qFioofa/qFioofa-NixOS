{ lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "usbhid"
    "thunderbolt"
  ];

  boot.kernelModules = [
    "kvm-intel"
    "huawei-wmi"
  ];

  boot.kernelParams = [ "acpi_osi=Linux" ];

  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

  hardware.enableRedistributableFirmware = true;

  hardware.graphics = {
    enable        = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  fileSystems."/" = {
    device  = "/dev/disk/by-uuid/61fd39f4-3c2f-4b85-a113-3578ea0900e1";
    fsType  = "ext4";
    options = [ "noatime" "errors=remount-ro" ];
  };

  fileSystems."/boot" = {
    device  = "/dev/disk/by-uuid/5F92-416F";
    fsType  = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
