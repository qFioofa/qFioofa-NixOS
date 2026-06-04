{ inputs, pkgs, ... }:
let
  # Build against the pinned nixpkgs (neovim 0.11.6 + its matching tree-sitter),
  # then bump the source to 0.11.7. Current unstable's tree-sitter removed APIs
  # 0.11.x still uses, so the override has to ride on the 0.11.x toolchain.
  pkgsNvim = inputs.nixpkgs-nvim.legacyPackages.${pkgs.system};

  neovim-0_11_7 = pkgsNvim.neovim-unwrapped.overrideAttrs (old: rec {
    version = "0.11.7";
    src = pkgsNvim.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v${version}";
      hash = "sha256-NAZAp4WSKYcEmwzhTy/OwYY4KO/dsUtjD0ddzMwm+8Q=";
    };
  });
in
{
  home.packages = [ (pkgsNvim.wrapNeovim neovim-0_11_7 { }) ];
}
