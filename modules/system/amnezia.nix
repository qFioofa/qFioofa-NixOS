{ ... }:
{
  programs.amnezia-vpn.enable = true;

  # AmneziaVPN rewrites DNS on connect. Have NetworkManager delegate DNS to
  # systemd-resolved so the two don't fight over /etc/resolv.conf.
  networking.networkmanager.dns = "systemd-resolved";

  # Prefer IPv4 when resolving dual-stack hostnames — works around an
  # amnezia-client bug (#2607) where unbracketed IPv6 endpoints break
  # amneziawg-go. IPv6 stays fully available; only address selection order changes.
  environment.etc."gai.conf".text = ''
    precedence ::ffff:0:0/96  100
  '';
}
