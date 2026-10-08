{ ... }:
# WSL2 host. NixOS-WSL supplies boot/init and networking; we only add the
# headless OS subset and the per-user config. No niri, no greetd, no hardware.
{
  imports = [
    ./user.nix
    ../../modules/wsl
  ];

  wsl.enable = true;
  wsl.defaultUser = "qFioofa";

  networking.hostName = "wsl";

  system.stateVersion = "24.11";
}
