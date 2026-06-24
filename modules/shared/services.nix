# Shared module: desktop services, portals, databases, and systemd user services.
{ ... }:

{
  imports = [
    ./sources/services.nix
  ];
}
