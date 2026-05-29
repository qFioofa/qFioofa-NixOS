{ pkgs, ... }: {
  # ── Screenshots ───────────────────────────────────────────────────────
  # niri has a built-in screenshot UI (Print key); these tools add an
  # annotated workflow: grim captures pixels, slurp selects a region, and
  # satty opens an editor to draw/crop before saving or copying. The combined
  # capture is bound to Mod+Shift+S in niri.nix.
  home.packages = [ pkgs.grim pkgs.slurp pkgs.satty ];
}
