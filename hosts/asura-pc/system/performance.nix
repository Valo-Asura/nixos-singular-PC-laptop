# PC-specific module: low-level desktop performance and memory pressure tuning.
{ ... }:

{
  services.irqbalance.enable = true;

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  programs.gamemode.enable = true;
  services.fstrim.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 5;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
    "vm.page-cluster" = 0;
    "vm.max_map_count" = 1048576;
    "vm.mglru_min_ttl_ms" = 1000;
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_queued_events" = 32768;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;
    "net.core.optmem_max" = 65536;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_wmem" = "4096 1048576 16777216";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_syncookies" = 1;
  };

  boot.kernelModules = [ "tcp_bbr" ];

  hardware.block.scheduler = {
    "nvme[0-9]*" = "kyber";
    "sd[a-z]" = "bfq";
    "mmcblk[0-9]*" = "bfq";
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "*";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];
}
