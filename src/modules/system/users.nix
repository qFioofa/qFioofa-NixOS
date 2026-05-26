{ pkgs, ... }: {
  users.users.qFioofa = {
    isNormalUser = true;
    extraGroups  = [ "networkmanager" "wheel" "audio" "video" "input" ];
    shell        = pkgs.zsh;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store   = true;
}
