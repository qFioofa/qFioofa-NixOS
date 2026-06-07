{ inputs, pkgs, ... }:
let
  proxy = inputs.tg-ws-proxy.packages.${pkgs.stdenv.hostPlatform.system}.default;

  host = "127.0.0.1";
  port = 1443;

  # The proxy generates a fresh MTProto secret on every start unless one is
  # passed in. Persist a random secret under the service's StateDirectory so the
  # Telegram connection details stay stable across restarts; create it on first
  # run if missing.
  startScript = pkgs.writeShellScript "tg-ws-proxy-start" ''
    set -eu
    secret_file="$STATE_DIRECTORY/secret"
    if [ ! -s "$secret_file" ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 16 > "$secret_file"
    fi
    secret=$(${pkgs.coreutils}/bin/cat "$secret_file")
    exec ${proxy}/bin/tg-ws-proxy --host ${host} --port ${toString port} --secret "$secret"
  '';
in
{
  # Local MTProto proxy for Telegram. Point Telegram Desktop at
  # ${host}:${toString port} using the secret stored at
  # /var/lib/tg-ws-proxy/secret (also logged on first start:
  # `journalctl -u tg-ws-proxy`).
  systemd.services.tg-ws-proxy = {
    description = "tg-ws-proxy — local MTProto proxy for Telegram";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      ExecStart = startScript;
      Restart = "on-failure";
      RestartSec = 5;

      DynamicUser = true;
      StateDirectory = "tg-ws-proxy";
      StateDirectoryMode = "0700";

      # Hardening — it only needs loopback networking and its state dir.
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    };
  };
}
