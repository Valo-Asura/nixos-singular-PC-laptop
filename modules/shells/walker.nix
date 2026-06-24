# Shared module: Walker launcher package and future shared config root.
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.walker
  ];

  home-manager.users.asura.xdg.configFile."walker/asura-shared.toml".text = ''
    # Shared Walker placeholder. No host-specific launcher settings here.
  '';
}
