# PC-specific module: CachyOS kernel for Ryzen 5 5600G class hardware.
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  # Lantian's Attic cache is intentionally not enabled by default: it returned
  # repeated HTTP 500/timeouts during rebuilds. Keep the CachyOS overlay active;
  # re-enable that cache only when the remote is healthy again.

  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
}
