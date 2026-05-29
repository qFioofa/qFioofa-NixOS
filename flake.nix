{
  description = "qFioofa NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./src/hosts/default.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
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
