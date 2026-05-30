{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ghostty terminal config (config + theme + cursor shader). Deployed
    # declaratively in src/home/apps/terminals/ghostty.nix instead of the
    # repo's scripts/deploy.sh.
    ghostty-config = {
      url = "github:qFioofa/qFioofa-Ghostty";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./src/hosts/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
          # Make flake inputs (ghostty-config, …) available to home modules.
          home-manager.extraSpecialArgs = { inherit inputs; };
          # Back up (instead of refusing to overwrite) any pre-existing real
          # files that home-manager wants to manage — e.g. a hand-written
          # ~/.config/niri/config.kdl from before this repo took over.
          home-manager.backupFileExtension = "backup";
          home-manager.users.qFioofa       = import ./src/home/default.nix;
        }
      ];
    };
  };
}
