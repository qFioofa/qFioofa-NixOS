{ ... }:
{
  imports = [
    ./boot.nix
    ./plymouth.nix
    ./locale.nix
    ./networking.nix
    ./amnezia.nix
    #./zapret.nix
    # ./tg-ws-proxy.nix
    ./audio.nix
    ./bash.nix
    ./bluetooth.nix
    ./fingerprint.nix
    ./nix-ld.nix
    ./huawei.nix
    ./users.nix
    ./docker.nix
    ./db.nix
    ./pangolin-db.nix
    ./network-lab.nix
    ./languages
  ];
}
