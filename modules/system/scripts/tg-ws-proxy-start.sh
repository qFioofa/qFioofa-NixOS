#!/usr/bin/env bash
set -eu
secret_file="$STATE_DIRECTORY/secret"
if [ ! -s "$secret_file" ]; then
  @openssl@ rand -hex 16 > "$secret_file"
fi
secret=$(@cat@ "$secret_file")
exec @proxy@ --host @host@ --port @port@ --secret "$secret"
