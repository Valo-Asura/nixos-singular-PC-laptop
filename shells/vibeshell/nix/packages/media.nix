# Shared VibeShell source helper: media package list.
{ pkgs }:

with pkgs;
[
  gpu-screen-recorder

  ffmpeg
  x264
  playerctl

  # Audio
  pipewire
  wireplumber
  mpvpaper
]
