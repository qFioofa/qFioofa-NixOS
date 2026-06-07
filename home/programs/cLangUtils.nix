{ pkgs, ... }:
{
  home.packages = with pkgs; [
    clang-tools
	  gnumake
	  cmakeCurses
    valgrind
    check
  ];
}
