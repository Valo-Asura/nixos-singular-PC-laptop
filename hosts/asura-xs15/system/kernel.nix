# Laptop-specific module: XS15 CachyOS kernel integration.
{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Use the pinned overlay so the selected CachyOS kernel matches the upstream
  # binary cache. The Colorful XS 22 / X15 XS is an Intel Alder Lake laptop;
  # x86_64-v3 is the correct cached target here.
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  nix.settings = {
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
}
