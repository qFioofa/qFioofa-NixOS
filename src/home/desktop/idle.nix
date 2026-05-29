{ pkgs, ... }: {
  # ── Idle & screen lock ────────────────────────────────────────────────
  # swayidle watches for inactivity; swaylock is the actual lock screen
  # (Catppuccin Mocha colors). Locks the screen after 5 min, powers off the
  # monitors after 10 min, and also locks right before the system suspends.
  # Manual lock is bound to Mod+Escape in niri.nix.
  programs.swaylock = {
    enable = true;
    settings = {
      color                = "1e1e2e";
      inside-color         = "1e1e2e";
      ring-color           = "cba6f7";
      key-hl-color         = "a6e3a1";
      line-color           = "1e1e2e";
      separator-color      = "1e1e2e";
      text-color           = "cdd6f4";
      inside-wrong-color   = "f38ba8";
      ring-wrong-color     = "f38ba8";
      indicator-radius     = 100;
      indicator-thickness  = 10;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { event = "lock";         command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "niri msg action power-off-monitors"; }
    ];
  };
}
