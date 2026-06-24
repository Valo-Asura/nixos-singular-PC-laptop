# asura-pc

PC host imported from `/home/asura/Downloads/hyprNixos-main/asuraPc`.

This host uses the current laptop/shared NixOS wiring as the source of truth for
apps, shells, wallpaper, Home Manager, and desktop behavior. Files here should
stay limited to PC-specific hardware, boot, filesystem, monitor, power, and
secret material.

First validation target:

```bash
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link
```
