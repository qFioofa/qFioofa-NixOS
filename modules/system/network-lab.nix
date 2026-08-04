{ pkgs, lib, ... }:
# Tooling for the School 21 "Networking basics" projects (GNS3 + Wireshark labs:
# Cisco IOS 3745 emulation, ICMP/ARP packet captures). GNS3 is installed as plain
# packages only — NOT services.gns3-server — because that systemd service has a
# project-creation bug the project README explicitly warns against; the GUI runs
# its own local server instead.
{
  # Wireshark Qt GUI. This also installs dumpcap with the right capabilities and
  # creates the `wireshark` group — the NixOS equivalent of the README's
  # `chmod +x /usr/bin/dumpcap` step (which doesn't apply here).
  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  environment.systemPackages = with pkgs; [
    gns3-gui      # GNS3 desktop client
    gns3-server   # local compute the GUI spawns (needs to be on PATH)
    dynamips      # Cisco IOS emulator (the 3745 image runs on this)
  ];

  # ubridge connects emulated NICs to the host and powers link packet captures.
  # It needs net capabilities, which a read-only Nix store binary can't carry, so
  # expose it through a setcap wrapper. /run/wrappers/bin is on PATH, so GNS3
  # picks up this capable `ubridge` automatically. Mirrors nixpkgs' own
  # gns3-server module. Reuses the wireshark group so lab users already have it.
  security.wrappers.ubridge = {
    source = lib.getExe pkgs.ubridge;
    capabilities = "cap_net_raw,cap_net_admin=eip";
    owner = "root";
    group = "wireshark";
    permissions = "u=rwx,g=rx,o=r";
  };
}
