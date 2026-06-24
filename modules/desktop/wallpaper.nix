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

  systemd.user.services.skwd-daemon = {
    description = "Skwd wallpaper daemon";
    documentation = [ "https://github.com/liixini/skwd-daemon" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${skwdWall}/bin/skwd-daemon";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [ "RUST_LOG=info" ];
    };
  };
}
