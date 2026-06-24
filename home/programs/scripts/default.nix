# Scripts configuration
{ ... }:

{
  imports = [
    ./modules/desktop-helpers.nix
    ./modules/legacy-screenshot.nix
    ./modules/night-shift.nix
  ];
}
