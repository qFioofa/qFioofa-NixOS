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
  # This unit (BoDE-WXX9, Tiger Lake) exposes:
  #   - a Conexant SN6140 analog HDA codec (0x14f1:1f87) on the normal HDA link
  #     — drives speakers, the headphone jack and the analog/headset mic;
  #   - a PCH DMIC advertised by NHLT (link PDM, device 0xae20, capture);
  #   - an ES8336 I2C codec on LPSS I2C controller #2 (\_SB_.PC00.I2C2 = PCI
  #     00:15.2), which is FIRMWARE-DISABLED on this board — that PCI function
  #     does not respond even to direct CF8/CFC port I/O, so it is gone, not just
  #     hidden, and no kernel/modprobe change can bring it back.
  #
  # The built-in microphone is the DMIC, wired to the Intel DSP and NOT to the
  # Conexant codec. Legacy HDA (dsp_driver=1) can therefore never record it,
  # which is the actual "no microphone" bug: the card exists, the analog pin
  # records only silence/DC, and Windows works because its Intel OED/AVS driver
  # drives the DSP. SOF (dsp_driver=3) is not an option either: it selects the
  # ES8336 machine driver, which waits forever on the dead I2C2 bus and
  # registers no card at all. Use AVS (dsp_driver=4).
  #
  # AVS needs Huawei's proprietary dsp_fw_release.bin (not in linux-firmware),
  # installed as intel/avs/tgl/dsp_basefw.bin. This copy was extracted from the
  # Windows driver already present on this machine:
  #   C:\Windows\System32\DriverStore\FileRepository\intcoed.inf_*/Fw/dsp_fw_release.bin
  # (the same blob as HUAWEI_Matebook_D_15_2022_ISST_*.zip / Fw/dsp_fw_release.bin).
  # The path is inside the flake and git-tracked, so pure evaluation works.
  hardware.huawei.matebook.audioDriver = "avs";
  hardware.huawei.matebook.avsFirmware = ./firmware/dsp_fw_release.bin;

  # If AVS fails to boot on this board revision, huawei.nix automatically
  # reloads legacy HDA and applies the Conexant/headset-mic workaround, so
  # speakers keep working. To force that path permanently (analog/headset mic
  # only, no built-in DMIC), change the two lines above to:
  #   hardware.huawei.matebook.audioDriver = "hda";
  #   hardware.huawei.matebook.micFix = true;
  # Known good on BOD-WXX9-PCB-B3; this B4 unit is what the firmware above was
  # taken from and is the first AVS target here.
}
