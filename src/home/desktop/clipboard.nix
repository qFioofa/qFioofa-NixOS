{ pkgs, ... }: {
  # ── Clipboard history ─────────────────────────────────────────────────
  # wl-clipboard provides wl-copy/wl-paste; cliphist keeps a searchable
  # history of everything copied. A user service runs `wl-paste --watch` to
  # record each new selection into the history. Browse and paste past entries
  # with Mod+V (piped through fuzzel --dmenu — see niri.nix binds).
  home.packages = [ pkgs.wl-clipboard pkgs.cliphist ];

  systemd.user.services.cliphist = {
    Unit = {
      Description = "cliphist clipboard history watcher";
      PartOf     = [ "graphical-session.target" ];
      After      = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
