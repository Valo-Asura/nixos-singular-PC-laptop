# Shared module: CachyOS kernel integration.
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Use the pinned overlay so the selected CachyOS kernel matches the upstream
  # binary cache. x86_64-v3 is the correct cached target here.
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  # Lantian's Attic cache is intentionally not enabled by default: it returned
  # repeated HTTP 500/timeouts during rebuilds. Keep the CachyOS overlay active;
  # re-enable that cache only when the remote is healthy again.

  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
}
