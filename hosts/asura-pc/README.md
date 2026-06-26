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
- The PC uses classic NixOS stage-1 initrd temporarily because the new
  CachyOS generation failed in systemd initrd with
  `Switch root target contains no usable init`.
- The PC does not define `rescue-no-nvidia`; that workaround is laptop-only.
- NVIDIA remains enabled, but it loads after initrd instead of inside initrd.
- Limine Secure Boot is active and keeps the PC boot path independent from the
  laptop systemd-boot setup.

After rebuilding, stale Limine, Atlas, old rescue, and missing-file boot entries
are cleaned from firmware and loader locations where possible. Duplicate Windows
firmware entries registered against the Linux ESP are removed, while the real
Windows Boot Manager entry on the Windows ESP is preserved.

Manual cleanup command, if a boot-only rebuild left stale menu entries:

```bash
sudo asura-pc-clean-boot-entries
```

## Secure Boot Next Steps

Current state:

- `boot.loader.limine.enable = true`.
- `boot.loader.limine.secureBoot.enable = true`.
- `boot.loader.efi.canTouchEfiVariables = true`.
- `systemd-boot` is forced off for this host.

Safe sequence for this host:

1. Prove normal unsigned boot first.

   ```bash
   sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
   sudo reboot
   ```

2. Boot the newest Limine/NixOS generation successfully.

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

7. Build and verify the Limine Secure Boot generation while Secure Boot is still
   disabled.

   ```bash
   sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
   sudo sbctl verify
   ```

8. Only if `sbctl verify` reports all required boot files signed, enable Secure Boot in firmware.

Do not run garbage collection until the newest signed generation has booted with Secure Boot enabled.
If Windows BitLocker is enabled, save the recovery key or suspend BitLocker before changing Secure Boot keys.
