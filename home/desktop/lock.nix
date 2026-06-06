{ pkgs, ... }:
let
  theme = import ../../theme.nix;
  inherit (theme) bg primary success error fg;
  # swaylock wants colours as RRGGBB[AA] without a leading '#'
  strip = c: builtins.substring 1 (builtins.stringLength c) c;
in
{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;

    settings = {
      # Blur the current screen instead of a flat colour for a modern look.
      screenshots = true;
      effect-blur = "8x5";
      effect-vignette = "0.4:0.4";
      fade-in = 0.2;

      clock = true;
      timestr = "%H:%M";
      datestr = "%a %d %B";

      indicator = true;
      indicator-radius = 110;
      indicator-thickness = 8;
      indicator-caps-lock = true;

      color = strip bg;
      inside-color = "${strip bg}cc";
      inside-ver-color = "${strip bg}cc";
      inside-wrong-color = "${strip bg}cc";
      inside-clear-color = "${strip bg}cc";

      ring-color = strip theme.bgSurface;
      ring-ver-color = strip primary;
      ring-wrong-color = strip error;
      ring-clear-color = strip success;

      key-hl-color = strip primary;
      bs-hl-color = strip error;

      line-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      line-clear-color = "00000000";
      separator-color = "00000000";

      text-color = strip fg;
      text-ver-color = strip primary;
      text-wrong-color = strip error;
      text-clear-color = strip fg;
    };
  };
}
