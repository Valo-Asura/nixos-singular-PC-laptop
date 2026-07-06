# Shared package helper note: the active VibeShell runtime wrapper is defined in modules/shells/vibeshell.nix.
{ pkgs }:

pkgs.writeTextDir "share/asura-vibeshell/README" ''
  VibeShell uses the shared source under /etc/nixos/shells/vibeshell.
  Package-only helpers, such as the Phosphor icon font, live in /etc/nixos/packages/vibeshell.
''
