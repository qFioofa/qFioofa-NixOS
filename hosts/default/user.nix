{ inputs, pkgs, ... }:
{
  users.users.qFioofa = {
    isNormalUser = true;
    description = "qFioofa";
    extraGroups = [ "wheel" "networkmanager" "video" "wireshark" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$9nOW.RGhJ/ja7JFJ$gc5TwpTvMVG9YkD0z73tjr34aAk7h4ExwFQXhrOT87eanmu0EKJvPqTmgrbEiozK65Api2PC7d8VgaI4o9XSs0";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.backupFileExtension = "hm-bak";

  home-manager.users.qFioofa = import ../../home/default.nix;
  home-manager.users.root = import ../root/default.nix;
}
