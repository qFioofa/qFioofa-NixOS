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
    ./bluetooth.nix
    ./huawei.nix
    ./users.nix
    ./docker.nix
    ./db.nix
  ];
}
