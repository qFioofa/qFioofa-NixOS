{ pkgs, ... }: {
  # ── XWayland support ──────────────────────────────────────────────────
  # niri is Wayland-only; xwayland-satellite is a rootless XWayland proxy
  # that lets X11 apps (Steam, Discord, games, Wine) run under niri. Since
  # niri 25.08 it is launched on demand automatically — it only needs to be
  # present on PATH, which this package provides.
  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
