{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-nvim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";

    # Pinned so `nix flake update` can't drag regreet to 0.4.0, which breaks the
    # greetd/regreet login (greeter exits, greetd crash-loops). This commit has
    # the known-good regreet 0.3.0. Bump only after login.nix is made
    # 0.4.0-compatible and tested on a reboot.
    nixpkgs-regreet.url = "github:NixOS/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DPI-bypass daemon (bol-van/zapret) packaged as a NixOS module.
    # zapret = {
    #   url = "github:aca/zapret-flake.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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
        # inputs.zapret.nixosModules.zapret
        home-manager.nixosModules.home-manager
        ./hosts/default/default.nix
      ];
    };

    nixosConfigurations.qFioofa = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        niri.nixosModules.niri
        # inputs.zapret.nixosModules.zapret
        home-manager.nixosModules.home-manager
        ./hosts/qFioofa/default.nix
      ];
    };
  };
}
