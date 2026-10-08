{ inputs, theme, homeConfigSpec, ... }:
# Home-manager wiring for the WSL host. Same surface as hosts/home-manager.nix
# but points the user at the headless profile (home/wsl.nix) and skips root.
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs theme homeConfigSpec; };
  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.qFioofa = import ../../home/wsl.nix;
}
