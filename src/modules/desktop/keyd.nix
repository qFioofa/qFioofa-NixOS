{ ... }: {
  # ── Tap-Super → app launcher ──────────────────────────────────────────
  # Wayland compositors (niri included) can only bind key *combinations*, never
  # a bare modifier press. keyd runs below the compositor and gives the left
  # Super/Meta key dual behaviour via overload():
  #   • held together with another key → still acts as Super, so every Mod+…
  #     niri bind keeps working unchanged;
  #   • tapped on its own and released  → emits F13.
  # niri binds F13 to the centered fuzzel launcher (see home/desktop/niri.nix),
  # so a quick tap of the Win key pops the minimalist app menu.
  #
  # ids = [ "*" ] applies to every keyboard. The layout switch (Alt+Shift) and
  # other keys are untouched — only leftmeta is remapped.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.leftmeta = "overload(meta, f13)";
    };
  };
}
