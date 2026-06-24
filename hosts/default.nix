# Shared host registry: laptop and PC host roots.
{ inputs, system, ... }:

{
  asura-xs15 = import ./asura-xs15 { inherit inputs system; };
  asura-pc = import ./asura-pc { inherit inputs system; };
}
