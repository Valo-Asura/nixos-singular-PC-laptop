# Shared package adapters: local package entrypoint for future host-neutral packages.
{
  inputs,
  pkgs,
  ...
}:

{
  skwd-wall = import ./skwd-wall { inherit inputs pkgs; };
}
