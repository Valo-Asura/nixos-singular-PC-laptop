# Shared module: skwd-wall is the active wallpaper backend for laptop and future PC.
{
  inputs,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  skwdWall = inputs.skwd-wall.packages.${system}.default;
in
{
  imports = [
    inputs.skwd-wall.nixosModules.default
  ];

  # vibewallREzero: disabled for now; skwd-wall is active.
  programs.skwd-wall.enable = true;

  environment.etc."asura-wallpaper/backend".text = ''
    skwd-wall
  '';

  # The upstream skwd-wall flake ships its own skwd-daemon.service unit.
  # We only override the ExecStart binary path to our resolved store path and
  # ensure it auto-starts.  The empty ExecStart= clears the upstream value
  # before setting ours — systemd requires exactly one ExecStart for
  # Type=simple services.
  systemd.user.services.skwd-daemon = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      ExecStart = [ "" "${skwdWall}/bin/skwd-daemon" ];
      Environment = [ "RUST_LOG=info" ];
    };
  };
}
