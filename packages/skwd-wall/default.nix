# Shared package adapter: active wallpaper backend comes from the skwd-wall flake input.
{ inputs, pkgs }:

inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.default
