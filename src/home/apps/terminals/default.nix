{ pkgs, ... }:
let
  # `terminal` execs the first terminal that is actually installed. ghostty is
  # the preferred default; the rest are graceful fallbacks. Used by niri's
  # Mod+Return and by $TERMINAL so anything that shells out to a terminal works.
  terminalLauncher = pkgs.writeShellScriptBin "terminal" ''
    for t in ghostty wezterm alacritty foot kitty xterm; do
      if command -v "$t" >/dev/null 2>&1; then
        exec "$t" "$@"
      fi
    done
    echo "terminal: no supported terminal emulator found" >&2
    exit 127
  '';
in {
  imports = [
    ./ghostty.nix
    ./alacritty.nix
    ./foot.nix
    ./wezterm.nix
  ];

  # ghostty + wezterm come from home.packages; alacritty/foot from their HM
  # modules (programs.*). The launcher must be on PATH for niri / $TERMINAL.
  home.packages = [ terminalLauncher pkgs.ghostty pkgs.wezterm ];
  home.sessionVariables.TERMINAL = "terminal";
}
