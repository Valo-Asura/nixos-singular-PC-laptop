# PC-specific host root: AMD/NVIDIA desktop imported from hyprNixos-main.
{ inputs, system, ... }:

let
  username = "asura";
  hostName = "asura-pc";
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit
      inputs
      system
      username
      hostName
      ;
    hostname = hostName;
  };

  modules = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.stylix.nixosModules.stylix
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix

    ../../modules/shared/nix.nix
    ../../modules/shared/networking.nix
    ../../modules/shared/users.nix
    ../../modules/shared/locale.nix
    ../../modules/shared/audio.nix
    ../../modules/shared/android.nix
    ../../modules/shared/kdeconnect.nix
    ../../modules/shared/services.nix
    ../../modules/shared/mysql.nix
    ../../modules/shared/virtual-machines.nix
    ../../modules/shared/programs.nix
    ../../modules/shared/gaming.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/environment.nix
    ../../modules/shared/maintenance.nix

    ../../modules/hardware/common.nix
    ../../modules/desktop/display-manager.nix
    ../../modules/desktop/theming.nix
    ../../modules/desktop/browser-theming.nix
    ../../modules/desktop/xdg.nix
    ../../modules/desktop/wallpaper.nix

    ../../modules/shells/waybar.nix
    ../../modules/shells/walker.nix
    ../../modules/shells/noctalia.nix
    ../../modules/shells/vibeshell.nix
    ../../modules/shells/switcher.nix

    ./system/boot.nix
    ./system/kernel.nix
    ./system/display.nix
    ./system/hardware.nix
    ./system/performance.nix
    ./system/desktop-performance.nix
    ./system/filesystems.nix
    ./system/windows-mount-helper.nix
    ./system/thermal.nix
    ./system/power.nix
    ./system/secrets.nix
    ./shell/active-shell.nix

    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        extraSpecialArgs = {
          inherit
            inputs
            system
            username
            hostName
            ;
          hostname = hostName;
        };
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.${username}.imports = [
          ../../home
          ./home/default.nix
        ];
      };
    }
  ];
}
