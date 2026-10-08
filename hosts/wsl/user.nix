{ pkgs, ... }:
# The single WSL user and its home-manager wiring. Same identity/password as
# the desktop hosts so dotfiles and credentials carry over, but without the
# hardware-adjacent groups (video/wireshark/plugdev) that don't exist under WSL.
{
  imports = [ ./home-manager.nix ];

  users.users.qFioofa = {
    isNormalUser = true;
    description = "qFioofa";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$9nOW.RGhJ/ja7JFJ$gc5TwpTvMVG9YkD0z73tjr34aAk7h4ExwFQXhrOT87eanmu0EKJvPqTmgrbEiozK65Api2PC7d8VgaI4o9XSs0";
  };

  # WSL is a personal dev box; passwordless sudo avoids the initial-password
  # dance and matches the default WSL experience.
  security.sudo.wheelNeedsPassword = false;
}
