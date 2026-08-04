{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # 7.7GB RAM, no swap -> OOM-killer aborts the VirtualBox VM. zram gives
  # compressed in-RAM swap so a 2GB guest survives memory spikes.
  zramSwap.enable = true;
}
