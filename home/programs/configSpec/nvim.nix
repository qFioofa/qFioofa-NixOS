{ inputs, pkgs, lib, config, ... }:
let
  cfg = config.qfioofa.nvim;

  pkgsNvim = inputs.nixpkgs-nvim.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  neovim-0_11_7 = pkgsNvim.neovim-unwrapped.overrideAttrs (old: rec {
    version = "0.11.7";
    src = pkgsNvim.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v${version}";
      hash = "sha256-NAZAp4WSKYcEmwzhTy/OwYY4KO/dsUtjD0ddzMwm+8Q=";
    };
  });

  mkNvim = neovim: pkgs.buildFHSEnv {
    name = "nvim";
    runScript = "nvim";
    targetPkgs = p: with p; [
      neovim
      stdenv.cc.cc.lib zlib openssl ncurses icu
      nodejs python3 go jdk21
      gcc gnumake curl wget git unzip gzip gnutar ripgrep fd
    ];
    profile = ''
      export LD_LIBRARY_PATH=/usr/lib:/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export CGO_ENABLED=0
    '';
  };

  neovim-0_12_3 = pkgsNvim.neovim-unwrapped.overrideAttrs (old: rec {
    version = "0.12.3";
    src = pkgsNvim.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v${version}";
      hash = "sha256-JjDU3GZf+wvsMyDjIfu1btTUBkOlpp6E1HFLqBLR9po=";
    };
  });

  builds = {
    "0.11.7" = mkNvim neovim-0_11_7;
    "0.12.3" = mkNvim neovim-0_12_3;
    "latest" = mkNvim pkgs.neovim-unwrapped;
  };
in
{
  options.qfioofa.nvim.version = lib.mkOption {
    type = lib.types.enum (builtins.attrNames builds);
    default = "0.12.3";
    description = ''
      Which Neovim to install as `nvim`. "0.11.7"/"0.12.3" = pinned; "latest" =
      whatever nixpkgs-nvim ships (now 0.11.6). Switch with a nixos-rebuild.
    '';
  };

  config = {
    home.packages = [ builds.${cfg.version} ];
    xdg.configFile."nvim" = {
      recursive = true;
      source = inputs.nvim-config;
    };
  };
}
