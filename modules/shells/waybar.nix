# Shared module: Waybar wrapper and single shared config under shells/waybar.
{
  config,
  pkgs,
  ...
}:

let
  waybarRoot = ../../shells/waybar;
  hyprlandPackage = config.programs.hyprland.package;

  asuraWaybar = pkgs.writeShellApplication {
    name = "asura-waybar";
    runtimeInputs = with pkgs; [
      coreutils
      hyprlandPackage
      jq
      networkmanagerapplet
      waybar
    ];
    text = ''
      exec waybar \
        -c /etc/xdg/waybar-asura/config.jsonc \
        -s /etc/xdg/waybar-asura/style.css "$@"
    '';
  };

  asuraWaybarSysbar = pkgs.writeShellApplication {
    name = "asura-waybar-sysbar";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      procps
    ];
    text = builtins.readFile (waybarRoot + "/scripts/sysbar.sh");
  };

  asuraWaybarWorkspaces = pkgs.writeShellApplication {
    name = "asura-waybar-workspaces";
    runtimeInputs = [
      hyprlandPackage
      pkgs.jq
    ];
    text = builtins.readFile (waybarRoot + "/scripts/workspaces.sh");
  };
in
{
  environment.systemPackages = [
    asuraWaybar
    asuraWaybarSysbar
    asuraWaybarWorkspaces
    pkgs.waybar
  ];

  environment.etc."xdg/waybar-asura".source = waybarRoot;

  home-manager.users.asura.home.packages = [
    asuraWaybar
    asuraWaybarSysbar
    asuraWaybarWorkspaces
  ];
}
