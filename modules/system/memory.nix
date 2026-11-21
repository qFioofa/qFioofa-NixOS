{ config, pkgs, ... }:
let
  # Values applied while the guard is on/off. Keeping both sets here means the
  # boot-time sysctl and the runtime switch can never drift apart.
  guard = {
    on = {
      swappiness = 150;
      watermarkScaleFactor = 200;
      minFreeKbytes = 262144;
    };
    off = {
      swappiness = 60;
      watermarkScaleFactor = 10;
      minFreeKbytes = 65536;
    };
  };

  # Root-side switch used by systemd; waybar only runs `memory-mode status`
  # and asks systemd to start memory-mode.service (allowed by the polkit rule
  # below), so no passwordless sudo entry is needed.
  memoryMode = pkgs.writeShellScriptBin "memory-mode" (
    builtins.readFile (
      pkgs.replaceVars ./scripts/memory-mode.sh {
        sysctl = "${pkgs.procps}/bin/sysctl";
        systemctl = "${config.systemd.package}/bin/systemctl";
        mkdir = "${pkgs.coreutils}/bin/mkdir";
        cat = "${pkgs.coreutils}/bin/cat";
        onSwappiness = toString guard.on.swappiness;
        onWatermarkScaleFactor = toString guard.on.watermarkScaleFactor;
        onMinFreeKbytes = toString guard.on.minFreeKbytes;
        offSwappiness = toString guard.off.swappiness;
        offWatermarkScaleFactor = toString guard.off.watermarkScaleFactor;
        offMinFreeKbytes = toString guard.off.minFreeKbytes;
      }
    )
  );
in
{
  # Compressed swap sized to RAM. On this 7.5 GiB laptop that is ~7.5 GiB of
  # zstd-backed swap; actual RAM use is much lower because the pages compress
  # roughly 4x, so this buys headroom without a dedicated partition.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    algorithm = "zstd";
    priority = 100;
  };

  # Emergency disk overflow. Only touched after zram is full: the zram device
  # has priority 100, this swapfile has priority 0 (higher wins first).
  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024; # MiB
      priority = 0;
    }
  ];

  # Kill the biggest memory hog before the machine starts thrashing. With
  # 15 GiB of total swap the default 10% swap gate would only fire after
  # heavy disk swapping, so make RAM the real trigger: freeSwapThreshold=100
  # means "any swap usage counts as low", which effectively gates on memory.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeMemKillThreshold = 5;
    freeSwapThreshold = 100;
    freeSwapKillThreshold = 100;
  };

  # Build parallelism is a RAM problem on this machine too: the default
  # `cores = 0` makes go build run `-p <ncpu>` and lets several heavy
  # derivations compile at once. Building tele (github.com/gotd/td/tg) that
  # way pushed MemAvailable under earlyoom's 10% gate, and it SIGTERM'd the
  # compiler ("signal: terminated"). Two jobs still fill cached rebuilds.
  nix.settings.cores = 2;

  # Reclaim earlier and keep a kernel free-page cushion so userspace cannot
  # drive the machine into direct reclaim (the usual cause of a hard freeze).
  boot.kernel.sysctl = {
    "vm.swappiness" = guard.on.swappiness;
    "vm.watermark_scale_factor" = guard.on.watermarkScaleFactor;
    "vm.min_free_kbytes" = guard.on.minFreeKbytes;
    # page-cluster is left at the default (3): zram prefers 0, but with a
    # disk swapfile in the mix the default is the safer compromise.
  };

  environment.systemPackages = [ memoryMode ];

  # Apply the persisted on/off choice after earlyoom/oomd and sysctl have
  # started, so a reboot with the guard disabled really boots it disabled.
  systemd.services.memory-mode-boot = {
    description = "Apply the saved memory guard state";
    wantedBy = [ "multi-user.target" ];
    after = [ "earlyoom.service" "systemd-oomd.service" "systemd-sysctl.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${memoryMode}/bin/memory-mode apply";
    };
  };

  # On-demand toggle run by waybar via `systemctl start memory-mode.service`.
  systemd.services.memory-mode = {
    description = "Toggle the memory guard";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${memoryMode}/bin/memory-mode toggle";
    };
  };

  # Let wheel users start the toggle without a password prompt. Only this one
  # unit is authorized; everything else still goes through normal polkit/sudo.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "memory-mode.service" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
}
