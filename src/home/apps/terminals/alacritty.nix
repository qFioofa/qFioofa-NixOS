{ ... }:
let
  inherit (import ./palette.nix) c font opacity;
in {
  # alacritty (fallback) — themed with the shared yugen-ash palette.
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity     = opacity;
        padding     = { x = 10; y = 10; };
        decorations = "none";
      };
      font = {
        normal.family = font;
        size          = 12.0;
      };
      colors = {
        primary   = { background = c.bg; foreground = c.fgBright; };
        cursor    = { cursor = c.primary; text = c.bg; };
        selection = { background = c.surface; text = c.fgBright; };
        normal = {
          black = c.bg;  red = c.red;     green = c.green;   yellow = c.yellow;
          blue  = c.blue; magenta = c.magenta; cyan = c.cyan; white = c.white;
        };
        bright = {
          black = c.muted; red = c.brRed;   green = c.brGreen; yellow = c.brYellow;
          blue  = c.brBlue; magenta = c.brMagenta; cyan = c.brCyan; white = c.brWhite;
        };
      };
    };
  };
}
