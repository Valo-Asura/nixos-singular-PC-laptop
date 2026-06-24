# /etc/nixos Structure

Active hosts:

- `asura-xs15`
- `asura-pc`

The flake exports both hosts from [hosts/default.nix](hosts/default.nix).

| Path | Comment |
|---|---|
| [flake.nix](flake.nix) | Single flake entry point. |
| [hosts/default.nix](hosts/default.nix) | Host registry. |
| [hosts/asura-xs15](hosts/asura-xs15) | Laptop-specific implementation. |
| [hosts/asura-xs15/system](hosts/asura-xs15/system) | Laptop boot, kernel, hardware, filesystems, thermal, NBFC, power, secrets. |
| [hosts/asura-xs15/hyprland](hosts/asura-xs15/hyprland) | Laptop monitor/layout only. |
| [hosts/asura-xs15/shell](hosts/asura-xs15/shell) | Laptop active shell selection. |
| [hosts/asura-pc](hosts/asura-pc) | Desktop implementation imported from `hyprNixos-main`. |
| [hosts/asura-pc/system](hosts/asura-pc/system) | PC boot, AMD/NVIDIA/Broadcom hardware, filesystems, power, thermal, secrets. |
| [hosts/asura-pc/hyprland](hosts/asura-pc/hyprland) | PC monitor/layout only. |
| [hosts/asura-pc/shell](hosts/asura-pc/shell) | PC active shell selection. |
| [modules/shared](modules/shared) | Shared NixOS apps, services, packages, users, locale, nix policy. |
| [modules/desktop](modules/desktop) | Shared desktop manager, theme, XDG, browser theme, wallpaper. |
| [modules/hardware](modules/hardware) | Shared hardware baseline. |
| [modules/shells](modules/shells) | Shared Waybar, Walker, Noctalia, VibeShell, shell switcher. |
| [home](home) | Shared Home Manager modules plus host overrides. |
| [home/desktop/hyprland](home/desktop/hyprland) | Shared Hyprland config, bindings, animations, lock/idle support. |
| [shells/waybar](shells/waybar) | One shared Waybar config. |
| [shells/walker](shells/walker) | Shared Walker config root. |
| [shells/noctalia](shells/noctalia) | Shared Noctalia config, loaded only when active shell is `noctalia`. |
| [shells/vibeshell](shells/vibeshell) | One shared VibeShell/Quickshell default config; no profiles. |
| [packages/skwd-wall](packages/skwd-wall) | Active shared wallpaper backend. |
| [packages/vibewallREzero](packages/vibewallREzero) | Disabled for now; `skwd-wall` is active. |

Shell choices:

```text
waybar
noctalia
vibeshell
```

Validation:

```bash
nix flake check --no-build /etc/nixos
nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel --no-link
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link
```
