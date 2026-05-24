{ config, pkgs, lib, ... }:

{
  # Amnezia VPN desktop client
  environment.systemPackages = [ pkgs.amnezia-vpn ];

  # TUN kernel module required for VPN tunnels
  boot.kernelModules = [ "tun" ];

  # Loose reverse-path filtering so VPN traffic is not dropped
  networking.firewall.checkReversePath = "loose";

  # Amnezia uses its own bundled WireGuard/OpenVPN — no extra services needed.
  # Import your .vpn config file from the Amnezia app after first boot.
}
