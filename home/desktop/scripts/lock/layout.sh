#!/usr/bin/env bash
T="@tmux@ -L screenlock -f @lockTmuxConf@"
$T kill-server 2>/dev/null || true
left=$($T   new-session   -d    -P -F '#{pane_id}' -s lock       "@activity@")
notifs=$($T split-window -h     -P -F '#{pane_id}' -t "$left"    -l 19% "@notifsPane@")
$T          split-window -v -b                     -t "$notifs"  -l 3   "@headerPane@"
$T          split-window -v -b                     -t "$notifs"  -l 3   "@clockPane@"
$T          split-window -v -b                     -t "$notifs"  -l 3   "@feedbackPane@"
$T          split-window -v -b                     -t "$notifs"  -l 8   "@calPane@"
$T          split-window -v -b                     -t "$notifs"  -l 3   "@statusPane@"
$T          split-window -v -b                     -t "$notifs"  -l 2   "@hwPane@"
$T          split-window -v -b                     -t "$notifs"  -l 5   "@sysPane@"
$T          split-window -v -b                     -t "$notifs"  -l 3   "@netPane@"
$T attach -t lock
$T kill-server 2>/dev/null || true
