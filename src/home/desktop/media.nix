{ pkgs, ... }: {
  # ── Media key control ─────────────────────────────────────────────────
  # playerctl talks to any MPRIS-capable player (browsers, mpv, Spotify) so
  # the XF86Audio Play/Pause/Next/Prev keys control playback regardless of
  # which app is focused. The keybinds live in niri.nix; this just installs
  # the binary they call.
  home.packages = [ pkgs.playerctl ];
}
