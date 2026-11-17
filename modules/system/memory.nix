{ ... }:
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

  # Reclaim earlier and keep a kernel free-page cushion so userspace cannot
  # drive the machine into direct reclaim (the usual cause of a hard freeze).
  boot.kernel.sysctl = {
    "vm.swappiness" = 150;
    "vm.watermark_scale_factor" = 200;
    "vm.min_free_kbytes" = 262144;
    # page-cluster is left at the default (3): zram prefers 0, but with a
    # disk swapfile in the mix the default is the safer compromise.
  };
}
