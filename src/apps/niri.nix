{ config, pkgs, lib, ... }:

{
  # Niri Wayland compositor
  programs.niri = {
    enable = true;
  };

  # Display manager (lightweight, Wayland-native)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # XDG portals (file picker, screen share, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # PipeWire audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  # GPU / hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Polkit (required for privileged GUI actions)
  security.polkit.enable = true;

  # Niri companion applications
  environment.systemPackages = with pkgs; [
    alacritty      # terminal emulator
    waybar         # status bar
    fuzzel         # app launcher
    swaylock       # screen locker
    swayidle       # idle / auto-lock manager
    mako           # desktop notifications
    wl-clipboard   # wl-copy / wl-paste
    grim           # screenshot tool
    slurp          # region selector (used with grim)
    brightnessctl  # backlight control
    pamixer        # volume control
  ];
}
