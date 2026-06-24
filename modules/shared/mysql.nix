# Shared module: local MySQL development service.
{ ... }:

{
  imports = [
    ./sources/mysql.nix
  ];
}
