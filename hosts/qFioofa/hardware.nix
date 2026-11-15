{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  # KVM hardware acceleration for the Android Emulator (VT-x on this CPU).
  boot.kernelModules = [ "kvm-intel" ];
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
  # card with speakers + headphone + analog mic. The Ubuntu BOD-WXX9 workaround
  # (hda-verb, enabled through micFix below) is what actually un-mutes/biases
  # that capture path; without it the card exists but records silence.
  hardware.huawei.matebook.audioDriver = "hda";
  hardware.huawei.matebook.micFix = true;

  # Internal DMIC instead of the analog/headset mic: the DMIC is only reachable
  # through the Intel DSP, and SOF cannot use it here because the ES8336/I2C2
  # link is dead. AVS does not need that link. It does need the Huawei
  # dsp_fw_release.bin (not shipped in linux-firmware); extract it from
  # HUAWEI_Matebook_D_15_2022_ISST_*.zip (Fw/dsp_fw_release.bin), then replace
  # the two lines above with:
  #   hardware.huawei.matebook.audioDriver = "avs";
  #   hardware.huawei.matebook.avsFirmware = ./firmware/dsp_fw_release.bin;
  # (a git-tracked path inside the flake works with pure evaluation; for an
  # external absolute path rebuild with `--impure`).
  # Known good on BOD-WXX9-PCB-B3; B4/B5 are untested with AVS.
}
