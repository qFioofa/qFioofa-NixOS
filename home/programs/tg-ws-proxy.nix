{ pkgs, ... }:
# Auto-configure Telegram Desktop to use the local MTProto proxy on login.
# The system service (modules/system/tg-ws-proxy.nix) writes the secret to
# /run/tg-ws-proxy/secret; this user service reads it and opens the
# tg://proxy protocol link so Telegram adds the proxy automatically.
{
  systemd.user.services.tg-ws-proxy-setup = {
    Unit = {
      Description = "Auto-configure Telegram Desktop for tg-ws-proxy";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      RemainAfterExit = false;

      # Wait for the system proxy to write the secret, then open the link.
      ExecStart = pkgs.writeShellScript "tg-ws-proxy-setup" ''
        set -eu

        secret_file=/run/tg-ws-proxy/secret
        timeout=30
        while [ ! -s "$secret_file" ] && [ "$timeout" -gt 0 ]; do
          sleep 1
          timeout=$((timeout - 1))
        done

        if [ ! -s "$secret_file" ]; then
          echo "tg-ws-proxy: secret file not found after 30 s, skipping" >&2
          exit 0
        fi

        secret=$(cat "$secret_file")
        link="tg://proxy?server=127.0.0.1&port=1443&secret=dd$secret"

        # Give the desktop session a moment to stabilise.
        sleep 3

        # Open the protocol link — Telegram Desktop registers tg:// in XDG.
        # Run it detached and return immediately: xdg-open blocks until the
        # launched app exits, and on a fresh login Telegram is not running yet
        # (so xdg-open spawns it itself and never returns). A blocking open
        # leaves this oneshot stuck in 'activating' forever, and every switch
        # then SIGTERMs the stale instance and re-starts the unit.
        (
          ${pkgs.xdg-utils}/bin/xdg-open "$link" >/dev/null 2>&1 \
            || ${pkgs.glib}/bin/gio open "$link" >/dev/null 2>&1 \
            || echo "tg-ws-proxy: could not open $link" >&2
        ) &
        exit 0
      '';
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
