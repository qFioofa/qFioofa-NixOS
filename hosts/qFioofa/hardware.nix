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
  # This unit (BoDE-WXX9, Tiger Lake) has TWO audio codecs:
  #   - a Conexant CX11880 analog HDA codec (0x14f1:1f87) on the normal HDA link
  #     — drives speakers, headphone jack and the analog/headset mic;
  #   - an ES8336 I2C codec on LPSS I2C controller #2 (\_SB_.PC00.I2C2 = PCI
  #     00:15.2), which is FIRMWARE-DISABLED on this board — that PCI function
  #     does not respond even to direct CF8/CFC port I/O, so it is gone, not just
  #     hidden, and no kernel/modprobe change can bring it back.
  # Forcing SOF (dsp_driver=3) routes everything through the ES8336 machine
  # driver, which then waits forever for its codec on the dead I2C2 bus
  # (`sof-essx8336 ... deferred probe pending`) and registers NO card at all —
  # the silent "Dummy Output", which also suppresses the working Conexant codec.
  # So use legacy HDA: snd-hda-intel binds the Conexant directly and gives a real
  # card with speakers + headphone + headset mic. Tradeoff: the internal digital
  # mic (DMIC) is only reachable via the dead ES8336/SOF path, so it stays dead;
  # the headset-jack mic works. (To revisit the DMIC you'd need I2C2 re-enabled
  # in firmware — a Huawei BIOS update / FSP UPD SerialIoI2cEnable[2].)
  hardware.huawei.matebook.audioDriver = "hda";
}
