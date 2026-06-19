{ pkgs, ... }:
{
  # Позволяет запускать непропатченные, прекомпилированные бинарники
  # (не из nixpkgs), которые ищут динамический линковщик и библиотеки
  # по стандартным путям (/lib64/ld-linux-x86-64.so.2 и т.п.).
  programs.nix-ld.enable = true;

  # Дополнительные библиотеки, которых часто не хватает таким бинарникам.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    glib
  ];
}
