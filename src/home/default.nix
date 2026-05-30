{ ... }: {
  imports = [
    ./apps/nvim.nix
    ./apps/tmux.nix
    ./apps/zsh.nix
    ./apps/git.nix
    ./apps/terminals
    ./desktop/niri.nix
    ./desktop/waybar.nix
    ./desktop/rofi.nix
    ./desktop/mako.nix
    ./desktop/idle.nix
    ./desktop/clipboard.nix
    ./desktop/screenshot.nix
    ./desktop/media.nix
  ];

  home = {
    username      = "qFioofa";
    homeDirectory = "/home/qFioofa";
    stateVersion  = "24.11";
  };

  programs.home-manager.enable = true;
  xdg.enable                   = true;
}
