#!/usr/bin/env bash
# Toggle launcher: a second keypress closes the overlay instead of stacking
# another instance. `-b 5` lays the five actions out as a single centered row;
# the side margins keep the tiles from stretching edge to edge on wide displays.
if @pgrep@ -x wlogout >/dev/null; then
  @pkill@ -x wlogout
else
  exec @wlogout@ -b 5 -T 360 -B 360 -L 80 -R 80
fi
