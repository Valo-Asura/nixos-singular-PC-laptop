# PC-specific module: local SOPS secrets.
{ lib, ... }:

let
  ageKeyFile = "/home/asura/.config/sops/age/keys.txt";
  hasAgeKey = builtins.pathExists ageKeyFile;
in
{
  sops = lib.mkIf hasAgeKey {
    defaultSopsFile = ../secrets/ambxst-ai.yaml;
    age.keyFile = ageKeyFile;
    secrets.GEMINI_API_KEY = {
      owner = "asura";
      mode = "0400";
    };
  };
}
