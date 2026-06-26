# Shared helper: build one NixOS host with common flake inputs and Home Manager wiring.
{ inputs, system }:

{
  hostName,
  modules,
  homeModules,
  username ? "asura",
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs system username;
    hostname = hostName;
    hostName = hostName;
  };
  modules = [
    inputs.stylix.nixosModules.stylix
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.sops-nix.nixosModules.sops
  ]
  ++ modules
  ++ [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        extraSpecialArgs = {
          inherit inputs system username;
          hostname = hostName;
          hostName = hostName;
        };
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        users.${username}.imports = homeModules;
      };
    }
  ];
}
