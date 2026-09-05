{ inputs, theme, homeConfigSpec, ... }:
# Shared home-manager wiring used by every host. Keeps the per-host user.nix
# files minimal: they only declare their own user(s) and groups.
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs theme homeConfigSpec; };
  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.qFioofa = import ../home/default.nix;
  home-manager.users.root = import ./root/default.nix;
}
