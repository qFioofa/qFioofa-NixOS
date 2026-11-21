# Runtime switch for the memory guard defined in modules/system/memory.nix.
# The systemd unit `memory-mode.service` runs `toggle` as root; waybar only
# calls `status` (unprivileged) and asks systemd to start the unit via polkit.
set -euo pipefail

STATE_DIR=/var/lib/memory-mode
STATE_FILE="$STATE_DIR/enabled"

apply_on() {
  @systemctl@ start systemd-oomd.socket systemd-oomd.service 2>/dev/null || true
  @systemctl@ start earlyoom.service
  @sysctl@ -q -w \
    vm.swappiness=@onSwappiness@ \
    vm.watermark_scale_factor=@onWatermarkScaleFactor@ \
    vm.min_free_kbytes=@onMinFreeKbytes@
  @mkdir@ -p "$STATE_DIR"
  printf '1\n' > "$STATE_FILE"
}

apply_off() {
  @systemctl@ stop earlyoom.service 2>/dev/null || true
  @systemctl@ stop systemd-oomd.service systemd-oomd.socket 2>/dev/null || true
  @sysctl@ -q -w \
    vm.swappiness=@offSwappiness@ \
    vm.watermark_scale_factor=@offWatermarkScaleFactor@ \
    vm.min_free_kbytes=@offMinFreeKbytes@
  @mkdir@ -p "$STATE_DIR"
  printf '0\n' > "$STATE_FILE"
}

is_on() {
  @systemctl@ is-active --quiet earlyoom.service
}

status_json() {
  if is_on; then
    text='󰌾'
    class='enabled'
    tip='Memory guard: ON\nearlyoom 10% / kill 5%, systemd-oomd on\nClick to disable'
  else
    text='󰌿'
    class='disabled'
    tip='Memory guard: OFF\nearlyoom and systemd-oomd stopped\nClick to enable'
  fi
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tip" "$class"
}

case "${1:-status}" in
  on)
    apply_on
    status_json
    ;;
  off)
    apply_off
    status_json
    ;;
  toggle)
    if is_on; then apply_off; else apply_on; fi
    status_json
    ;;
  apply)
    if [ -f "$STATE_FILE" ] && [ "$(@cat@ "$STATE_FILE")" = "0" ]; then
      apply_off
    else
      apply_on
    fi
    ;;
  status)
    status_json
    ;;
  *)
    echo "usage: memory-mode {on|off|toggle|apply|status}" >&2
    exit 2
    ;;
esac
