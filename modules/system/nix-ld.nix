{ pkgs, ... }:
{
  # Позволяет запускать непропатченные, прекомпилированные бинарники
  # (не из nixpkgs), которые ищут динамический линковщик и библиотеки
  # по стандартным путям (/lib64/ld-linux-x86-64.so.2 и т.п.).
  #
  # Это язык-агностично: LSP-серверы из mason/npm/pip/cargo/go, вендоренные
  # тулчейны, VS Code remote servers и т.п. находят общие .so в рантайме
  # вместо падения с "required file not found".
  programs.nix-ld.enable = true;

  # Дополнительные библиотеки, которых часто не хватает таким бинарникам.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc        # libstdc++, libgcc_s — нужно почти всем
    zlib
    zstd
    openssl
    curl
    glib
    icu                 # node, dotnet, многие CLI
    libxml2
    expat
    bzip2
    xz
    ncurses
    readline
    util-linux          # libuuid
    libuv
    libGL
    libxkbcommon
    fuse3
    dbus
    fontconfig
    freetype
  ];
}
