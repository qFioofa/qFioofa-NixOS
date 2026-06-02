{ pkgs, ... }:
{
  users.users.qFioofa = {
    isNormalUser = true;
    description = "qFioofa";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
