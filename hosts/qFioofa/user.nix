{ inputs, pkgs, ... }:
{
  imports = [ ../home-manager.nix ];

  users.users.qFioofa = {
    isNormalUser = true;
    description = "qFioofa";
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "wireshark" "plugdev" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$9nOW.RGhJ/ja7JFJ$gc5TwpTvMVG9YkD0z73tjr34aAk7h4ExwFQXhrOT87eanmu0EKJvPqTmgrbEiozK65Api2PC7d8VgaI4o9XSs0";
  };
}
