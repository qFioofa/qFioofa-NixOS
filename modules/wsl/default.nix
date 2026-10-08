{ ... }:
# OS-level subset for the headless WSL2 host. It mirrors the parts of
# modules/system that make sense under WSL and deliberately drops everything
# tied to real hardware or a graphical session (boot, plymouth, audio,
# bluetooth, fingerprint, security-key, huawei, virtualbox, network-lab,
# amnezia, tg-ws-proxy, zapret, cisco-vpn) as well as all of modules/desktop.
{
  imports = [
    ../system/locale.nix
    ../system/nix-ld.nix
    ../system/bash.nix
    ../system/users.nix
    ../system/languages
    ../system/docker.nix
    ./networking.nix
  ];
}
