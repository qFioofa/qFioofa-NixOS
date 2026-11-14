{ lib, ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  # Start the dispatcher from boot instead of leaving it purely D-Bus-activated,
  # so /etc/NetworkManager/dispatcher.d hooks are live from early boot.
  systemd.services.NetworkManager-dispatcher = {
    enable = true;
    wantedBy = lib.mkForce [ "multi-user.target" ];
  };

  networking.extraHosts = ''
    127.0.0.1 store.local
  '';

  networking.networkmanager.ensureProfiles.profiles."Advance Network Configuration" = {
    connection = {
      id = "Advance Network Configuration";
      type = "wifi";
      autoconnect = true;
    };
    ipv4 = {
      method = "auto";
    };
    ipv6 = {
      addr-gen-mode = "stable-privacy";
      method = "auto";
    };
    wifi = {
      mode = "infrastructure";
      ssid = "Advance Network Configuration";
    };
    wifi-security = {
      auth-alg = "open";
      key-mgmt = "none";
    };
  };
}
