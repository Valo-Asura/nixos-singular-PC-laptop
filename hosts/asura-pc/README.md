# asura-pc

PC host imported from `hyprNixos-main/asuraPc`.

This host uses the current laptop/shared NixOS wiring as the source of truth for
apps, shells, wallpaper, Home Manager, and desktop behavior. Files here should
stay limited to PC-specific hardware, boot, filesystem, monitor, power, and
secret material.

First validation target:

```bash
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link
```

Install the next boot generation:

```bash
sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
```

Keep garbage collection off until the newest generation has booted cleanly.
