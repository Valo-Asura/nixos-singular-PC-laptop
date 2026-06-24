# Shared module: Nix registry, flake settings, hostname, and nixpkgs policy.
{
  hostname,
  inputs,
  ...
}:

{
  networking.hostName = hostname;

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-substitution-jobs = 64;
      http-connections = 128;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
