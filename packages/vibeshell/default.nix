# Shared package placeholder: VibeShell runtime wrapper is defined in modules/shells/vibeshell.nix.
{ pkgs }:

pkgs.writeTextDir "share/asura-vibeshell/README" ''
  VibeShell uses the shared source under /etc/nixos/shells/vibeshell.
''
