{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned nixpkgs for Neovim: this rev ships neovim 0.11.6 with the matching
    # tree-sitter. We bump the source to 0.11.7 on top of it (see configSpec/nvim.nix).
    # Unstable jumped 0.11.6 -> 0.12.x, whose tree-sitter drops APIs that 0.11.x needs.
    nixpkgs-nvim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own set of configurations
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
        home-manager.nixosModules.home-manager
        ./hosts/default/default.nix
      ];
    };

    nixosConfigurations.qFioofa = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        niri.nixosModules.niri
        home-manager.nixosModules.home-manager
        ./hosts/qFioofa/default.nix
      ];
    };
  };
}
