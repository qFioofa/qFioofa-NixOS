{ ... }:
let
  inherit (import ./palette.nix) c font opacity bare;
in {
  # foot (lightweight wayland fallback) — yugen-ash palette (bare 6-digit hex).
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "${font}:size=12";
        pad  = "10x10";
      };
      colors = {
        alpha      = opacity;
        background = bare c.bg;
        foreground = bare c.fgBright;
        regular0 = bare c.bg;     regular1 = bare c.red;     regular2 = bare c.green;
        regular3 = bare c.yellow; regular4 = bare c.blue;    regular5 = bare c.magenta;
        regular6 = bare c.cyan;   regular7 = bare c.white;
        bright0  = bare c.muted;  bright1  = bare c.brRed;   bright2  = bare c.brGreen;
        bright3  = bare c.brYellow; bright4 = bare c.brBlue; bright5  = bare c.brMagenta;
        bright6  = bare c.brCyan; bright7  = bare c.brWhite;
      };
      cursor.color = "${bare c.bg} ${bare c.primary}";
    };
  };
}
