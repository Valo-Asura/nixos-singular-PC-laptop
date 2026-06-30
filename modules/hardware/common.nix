# Shared module: common hardware baseline; host-specific hardware stays under hosts/<host>/system.
{ ... }:

{
  # Shared NVMe baseline: keep SSD latency predictable without hiding device
  # stats from desktop/resource monitors. Host performance modules choose the
  # scheduler; these queue knobs are safe for both laptop and PC NVMe devices.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="128"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rq_affinity}="2"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/add_random}="0"
  '';
}
