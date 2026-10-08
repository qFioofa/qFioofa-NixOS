{ ... }:
# WSL-specific networking. Unlike modules/system/networking.nix we do NOT
# enable NetworkManager — WSL2 manages the virtual NIC itself; running NM on
# top of it causes flapping. NixOS-WSL owns /etc/hosts generation, so the
# desktop `store.local` alias (unused outside the LAN) is intentionally dropped.
{
  networking.firewall.enable = false;
}
