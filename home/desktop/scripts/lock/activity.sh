#!/usr/bin/env bash
case $(( $(@od@ -An -N1 -tu1 /dev/urandom) % 8 )) in
  0|1) exec @asciiquarium@ ;;
  2|3) exec @cbonsai@ -l -i -t 0.04 ;;
  4)   exec @cmatrix@ -b -u 6 ;;
  5)   exec @lavat@ -c red ;;
  *)   exec @pipes@ ;;
esac
