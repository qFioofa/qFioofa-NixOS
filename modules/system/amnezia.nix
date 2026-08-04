{ ... }:
{
  programs.amnezia-vpn.enable = true;

  networking.networkmanager.dns = "systemd-resolved";

  environment.etc."gai.conf".text = ''
    precedence ::ffff:0:0/96  100
  '';
}
