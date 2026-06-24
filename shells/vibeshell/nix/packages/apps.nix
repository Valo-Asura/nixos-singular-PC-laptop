# Shared VibeShell source helper: application package list for the single default config.
{ pkgs }:

with pkgs; [
  # Terminal
  foot
  tmux

  # Launcher
  fuzzel

  # Control panels
  networkmanagerapplet
  blueman
  pwvucontrol
  gradia

  # Icons
  adwaita-icon-theme
  kdePackages.breeze-icons
  hicolor-icon-theme
  papirus-icon-theme
]
