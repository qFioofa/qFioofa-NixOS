{ pkgs, ... }: {
  # ── Idle & screen lock ────────────────────────────────────────────────
  # swayidle watches for inactivity; swaylock is the actual lock screen
  # (yugen-ash colors — matches niri.nix / waybar). Locks the screen after
  # 5 min, powers off the monitors after 10 min, and also locks right before
  # the system suspends. Manual lock is bound to Mod+Escape in niri.nix.
  #
  # NOTE: swaylock can only verify the password because the system enables the
  # PAM service `security.pam.services.swaylock` (see modules/desktop/niri.nix).
  programs.swaylock = {
    enable = true;
    settings = {
      color                = "151515";
      inside-color         = "151515";
      ring-color           = "FFBE89";
      key-hl-color         = "7EAB8E";
      line-color           = "151515";
      separator-color      = "151515";
      text-color           = "D4D4D4";
      inside-wrong-color   = "F57A7A";
      ring-wrong-color     = "F57A7A";
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
