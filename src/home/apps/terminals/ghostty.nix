{ inputs, ... }: {
  # ghostty is the default terminal. Its config is deployed verbatim from the
  # upstream qFioofa-Ghostty flake input (the repo's scripts/deploy.sh just
  # `cp -r src/. ~/.config/ghostty`; we reproduce that layout declaratively from
  # the locked input). Relative `theme = yugen-ash.conf` and
  # `custom-shader = shaders/cursor.glsl` resolve next to the config file.
  #
  # Managed via xdg.configFile, so the programs.ghostty HM module is NOT used
  # (it would fight over ~/.config/ghostty/config). The ghostty package itself
  # is installed in ./default.nix's home.packages.
  xdg.configFile."ghostty/config".source =
    "${inputs.ghostty-config}/src/config";
  xdg.configFile."ghostty/themes/yugen-ash.conf".source =
    "${inputs.ghostty-config}/src/themes/yugen-ash.conf";
  xdg.configFile."ghostty/shaders/cursor.glsl".source =
    "${inputs.ghostty-config}/src/shaders/cursor.glsl";
}
