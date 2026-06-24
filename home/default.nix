# Shared Home Manager entrypoint: common user config for all Asura hosts.
{ inputs, pkgs, ... }:

{
  imports = [
    ./shared/apps.nix
    ./shared/browser.nix
    ./shared/ai-memory.nix
    ./shared/programs.nix
    ./shared/shell.nix
    ./shared/vscode.nix
    ./shared/templates.nix
    ./desktop/hyprland
    ./desktop/theming
  ];

  home = {
    username = "asura";
    homeDirectory = "/home/asura";
    stateVersion = "25.11";
  };

  xdg.userDirs = {
    enable = true;
    # Keep the pre-26.05 behavior explicit and silence the Home Manager warning.
    setSessionVariables = true;
  };

  # The shell owns the network tray/control surface. Keep nm-connection-editor
  # available, but prevent nm-applet's legacy tray autostart warnings.
  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=NetworkManager Applet
    Hidden=true
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
