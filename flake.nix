{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ghostty config — provides homeManagerModules.default that links src/ to ~/.config/ghostty
    ghostty-config.url = "github:qFioofa/qFioofa-Ghostty";
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
