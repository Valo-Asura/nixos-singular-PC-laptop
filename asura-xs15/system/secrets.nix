# SOPS secrets for local AI tools.
{ lib, ... }:

let
  ageKeyFile = "/home/asura/.config/sops/age/keys.txt";
  hasAgeKey = builtins.pathExists ageKeyFile;
in
{
  # Fresh installs may not have the age key restored yet.
  # Keep system activation working; secrets can be re-enabled by restoring the key.
  sops = lib.mkIf hasAgeKey {
    defaultSopsFile = ../secrets/ambxst-ai.yaml;
    age.keyFile = ageKeyFile;
    secrets.GEMINI_API_KEY = {
      owner = "asura";
      mode = "0400";
    };
  };
}
