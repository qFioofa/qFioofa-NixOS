{ ... }:
{
  imports = [
    ./boot.nix
    ./plymouth.nix
    ./locale.nix
    ./networking.nix
    ./amnezia.nix
    ./audio.nix
    ./bash.nix
    ./bluetooth.nix
    ./fingerprint.nix
    ./security-key.nix
    ./nix-ld.nix
    ./huawei.nix
    ./users.nix
    ./docker.nix
    ./virtualbox.nix
    ./db.nix
    ./network-lab.nix
    ./languages
  ];
}
