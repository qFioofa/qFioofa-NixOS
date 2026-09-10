#!/usr/bin/env bash
set -eu
secret_file="$STATE_DIRECTORY/secret"
if [ ! -s "$secret_file" ]; then
  @openssl@ rand -hex 16 > "$secret_file"
fi
secret=$(@cat@ "$secret_file")
# Expose the secret to user-level services via /run so tg-ws-proxy-setup
# can auto-configure Telegram Desktop on login.
@printf@ '%s' "$secret" > /run/tg-ws-proxy/secret
exec @proxy@ --host @host@ --port @port@ --secret "$secret"
