{ pkgs, inputs, ... }:
# tele — terminal-native Telegram client (github.com/sorokin-vladimir/tele).
# The daemon keeps the account connected from login and delivers desktop
# notifications with no window open; `tele` started from a terminal joins it.
# Do not run `tele daemon install`: it would overwrite this unit.
#
# Proxy: route tele through the local tg-ws-proxy (modules/system/tg-ws-proxy.nix)
# by putting this in ~/.config/tele/config.yml before the first launch:
#
#   proxy:
#     type: mtproto
#     server: 127.0.0.1
#     port: 1443
#     secret: <cat /run/tg-ws-proxy/secret>
#
# The config file stays app-managed (the `,` settings overlay writes to it), so
# it is not declared here — a rebuild would otherwise undo in-app changes.
let
  tele = inputs.tele.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ tele ];

  systemd.user.services.tele = {
    Unit = {
      Description = "tele — terminal Telegram client daemon";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${tele}/bin/tele daemon --service";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
