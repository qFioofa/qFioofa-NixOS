#!/usr/bin/env bash
exec 9>&-
exec @windowtolayer@ -- \
  @alacritty@ --config-file @alacrittyConf@ -e @lockLayout@
