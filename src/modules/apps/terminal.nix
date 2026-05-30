{ pkgs, ... }: {
  # Terminal emulators themselves are installed per-user via home-manager
  # (see src/home/apps/terminals/ — ghostty default + wezterm/alacritty/foot
  # fallbacks). This module only carries the desktop helper utilities that the
  # session and keybinds depend on.
  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim slurp        # screenshot
    brightnessctl
    pavucontrol
  ];
}
