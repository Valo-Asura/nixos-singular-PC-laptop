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

## Boot Recovery Notes

- PC Plymouth is disabled until the newest generation boots cleanly.
- Boot status is intentionally visible with `systemd.show_status=true`.
- The PC does not define `rescue-no-nvidia`; that workaround is laptop-only.
- NVIDIA remains enabled, but it loads after initrd instead of inside initrd.
- systemd-boot keeps 5 generations to preserve rollback room while reducing menu noise.

After rebuilding, old `rescue-no-nvidia`, Limine, Atlas, and missing-file entries
are removed from `/boot/loader/entries` by the activation script. Duplicate
Windows firmware entries registered against the Linux ESP are removed, while the
real Windows Boot Manager entry on the Windows ESP is preserved.

## Secure Boot Next Steps

Current state:

- `systemd-boot` is active.
- `boot.loader.efi.canTouchEfiVariables = true`.
- `boot.lanzaboote.enable = false`.
- Secure Boot should stay disabled in firmware until signing is complete.

Safe sequence:

1. Prove normal unsigned boot first.

   ```bash
   sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
   sudo reboot
   ```

2. Boot the newest `Linux Boot Manager` / NixOS generation successfully with Secure Boot still disabled.

3. Check sbctl state.

   ```bash
   sudo sbctl status
   ```

4. If keys do not exist, create them.

   ```bash
   sudo sbctl create-keys
   ```

5. In firmware, switch Secure Boot to setup/custom mode or clear existing Secure Boot keys. Keep Microsoft key support planned because this host also boots Windows.

6. Back in NixOS, enroll keys with Microsoft compatibility.

   ```bash
   sudo sbctl enroll-keys --microsoft
   sudo sbctl status
   ```

7. Enable Lanzaboote in [system/boot.nix](system/boot.nix):

   ```nix
   boot.loader.systemd-boot.enable = lib.mkForce false;
   boot.lanzaboote = {
     enable = true;
     pkiBundle = "/var/lib/sbctl";
   };
   ```

8. Build the signed boot generation while Secure Boot is still disabled.

   ```bash
   sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
   sudo sbctl verify
   ```

9. Only if `sbctl verify` reports all required boot files signed, enable Secure Boot in firmware.

Do not run garbage collection until the newest signed generation has booted with Secure Boot enabled.
If Windows BitLocker is enabled, save the recovery key or suspend BitLocker before changing Secure Boot keys.
