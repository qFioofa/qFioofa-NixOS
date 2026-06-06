{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/root";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_BOOT";
    fsType = "vfat";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

  # This host is the Huawei Matebook — enable the vendor quirk fixes (audio
  # Dummy Output / dead mic, IPU6 camera). Defined in modules/system/huawei.nix
  # and only ever switched on here, so other hosts are unaffected.
  hardware.huawei.matebook.enable = true;
}
