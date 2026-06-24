# Shared host registry: only asura-xs15 is implemented now; asura-pc is a placeholder.
{ inputs, system, ... }:

{
  asura-xs15 = import ./asura-xs15 { inherit inputs system; };
}
