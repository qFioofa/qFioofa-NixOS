{ ... }: {
  # yugen-ash palette — keep in sync with niri.nix / waybar / terminals.
  # Current home-manager dropped the flat options (backgroundColor, …) in favour
  # of services.mako.settings; criteria like [urgency=low] are nested attrsets.
  services.mako = {
    enable = true;
    settings = {
      font             = "JetBrainsMono Nerd Font Mono 11";
      width            = 380;
      border-radius    = 8;
      border-size      = 2;
      default-timeout  = 5000;
      background-color = "#151515";
      text-color       = "#D4D4D4";
      border-color     = "#FFBE89";

      "urgency=low" = {
        border-color = "#96A8AD";
      };

      "urgency=high" = {
        border-color    = "#F57A7A";
        default-timeout = 0;
      };
    };
  };
}
