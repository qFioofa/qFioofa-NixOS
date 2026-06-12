{ pkgs, lib, ... }:
let
  # C/C++ libraries that should be visible to the toolchain system-wide.
  # Add a library here and its <header.h>, -l<name> flag and pkg-config entry
  # are wired up automatically for every shell and GUI app — no per-lib tweaks.
  cLibs = with pkgs; [
    check
  ];

  # The `gcc` wrapper exposes gcc/g++/cpp but NOT `gcov`. `gcovr` (and lcov)
  # shell out to a `gcov` binary, so without it `make gcov_report` fails to read
  # coverage data. Expose only the `gcov` from the matching unwrapped gcc so it
  # doesn't shadow the wrapped `gcc` in PATH.
  gcov = pkgs.runCommand "gcov" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.gcc-unwrapped}/bin/gcov $out/bin/gcov
  '';
in
{
  programs.zsh.enable = true;

  # System-wide C/C++ dev support: the libraries above plus coverage tooling.
  # gcovr / lcov consume the gcov data emitted by `gcc/clang --coverage`.
  environment.systemPackages = (with pkgs; [ gcovr lcov ]) ++ [ gcov ] ++ cLibs;

  # NixOS has no global /usr/include or /usr/lib, so the toolchain can't see
  # installed libraries out of the box. Resolve the real Nix store paths of each
  # library above — makeSearchPathOutput/makeLibraryPath expand to
  # `<store>/include`, `<store>/lib`, `<store>/lib/pkgconfig`, preferring the
  # `dev` output when a package splits its headers out — and export them as
  # session variables. NixOS writes these into /etc/set-environment, which every
  # login session sources, so they reach any shell and GUI-launched app
  # naturally; no hand-sourced hm-session-vars.sh needed. This makes
  #   #include <check.h>     gcc test.c -lcheck     pkg-config --cflags check
  # all work directly.
  environment.sessionVariables = {
    C_INCLUDE_PATH     = lib.makeSearchPathOutput "dev" "include" cLibs;
    CPLUS_INCLUDE_PATH = lib.makeSearchPathOutput "dev" "include" cLibs;
    LIBRARY_PATH       = lib.makeLibraryPath cLibs;
    PKG_CONFIG_PATH    = lib.makeSearchPathOutput "dev" "lib/pkgconfig" cLibs;
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
