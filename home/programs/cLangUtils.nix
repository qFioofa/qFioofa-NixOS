{ pkgs, ... }:
{
  # C/C++ developer tooling for this user. The libraries themselves and the
  # include / lib / pkg-config search paths are configured system-wide in
  # modules/system/users.nix, so every shell and GUI app sees them naturally.
  home.packages = with pkgs; [
    clang-tools
    gnumake
    cmakeCurses
    valgrind
  ];
}
