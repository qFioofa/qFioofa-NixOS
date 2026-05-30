# Shared terminal theming — yugen-ash (main variant) palette, hardcoded.
# Pure data: `import`ed by each terminal module, no external dependency.
rec {
  font    = "JetBrainsMono Nerd Font Mono";
  opacity = 0.95;

  # Strip the leading '#' (foot wants bare 6-digit hex).
  bare = s: builtins.substring 1 6 s;

  c = {
    bg       = "#151515"; # color700
    bgAlt    = "#000000"; # color800
    surface  = "#303030"; # color600
    overlay  = "#505050"; # color500
    muted    = "#696969"; # color400
    subtext  = "#A9A9A9"; # color300
    fg       = "#D4D4D4"; # color200
    fgBright = "#FAFAFA"; # color100

    primary  = "#FFBE89"; # accent / cursor
    red      = "#F57A7A"; # error
    green    = "#7EAB8E"; # success
    yellow   = "#FFF2AF"; # warning
    blue     = "#79A0AA"; # tide
    magenta  = "#C678DD"; # violet
    cyan     = "#8DD3C3"; # seafoam
    white    = "#D4D4D4";

    brRed     = "#FF9E8B"; # coral
    brGreen   = "#9DB89C"; # sage
    brYellow  = "#D4A76A"; # amber
    brBlue    = "#96A8AD"; # frost
    brMagenta = "#C678DD";
    brCyan    = "#8DD3C3";
    brWhite   = "#FAFAFA";
  };
}
