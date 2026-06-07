{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-nvim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DPI-bypass daemon (bol-van/zapret) packaged as a NixOS module.
    zapret = {
      url = "github:aca/zapret-flake.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Local MTProto proxy that accelerates Telegram (Flowseal/tg-ws-proxy).
    tg-ws-proxy = {
      url = "github:pialtor/tg-ws-proxy-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty-config.url = "github:qFioofa/qFioofa-Ghostty";
    zsh-config.url = "github:qFioofa/qFioofa-zsh";
    wezterm-config.url = "github:qFioofa/qFioofa-wezterm";
    tmux-config.url = "github:qFioofa/qFioofa-tmux";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, niri, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        niri.nixosModules.niri
        inputs.zapret.nixosModules.zapret
        home-manager.nixosModules.home-manager
        ./hosts/default/default.nix
      ];
    };

    nixosConfigurations.qFioofa = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        niri.nixosModules.niri
        inputs.zapret.nixosModules.zapret
        home-manager.nixosModules.home-manager
        ./hosts/qFioofa/default.nix
      ];
    };
  };
}
