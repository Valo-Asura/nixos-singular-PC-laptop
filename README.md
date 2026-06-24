# Asura NixOS

Single `/etc/nixos` flake for the laptop and desktop.

## Current State

| Area | Value |
|---|---|
| Repo | `Valo-Asura/nixos-singular-PC-laptop` |
| Hosts | `asura-xs15`, `asura-pc` |
| NixOS input | `nixos-unstable` / `26.11.20260616.567a49d` |
| Hyprland | stable `v0.55.4` from the official Hyprland flake |
| Kernel | CachyOS kernel `7.1.1` from `nix-cachyos-kernel/release` |
| Default shell | `vibeshell` on both hosts |
| Shell choices | `waybar`, `noctalia`, `vibeshell` |
| Wallpaper | shared `skwd-wall`; `vibewallREzero` is parked as disabled source |
| File manager | Nautilus default, PCManFM-Qt available |
| Downloads | Xtreme Download Manager with Firefox and Chromium-family helpers |

## Commands

```bash
sudo nixos-rebuild test --flake /etc/nixos#asura-xs15
sudo nixos-rebuild switch --flake /etc/nixos#asura-xs15

nix flake check --no-build /etc/nixos
nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel --no-link
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link

asura-shell-switch current
asura-shell-switch autostart
asura-shell-switch vibeshell
asura-shell-switch noctalia
asura-shell-switch waybar

skwd-wall
asura-screenshot full
asura-screen-record-toggle
thermal-status
nbfc-colorful-verify
```

## Structure

| Path | Comment |
|---|---|
| [flake.nix](flake.nix) | Single flake; exports `asura-xs15` and `asura-pc`. |
| [flake.lock](flake.lock) | Locked unstable apps, CachyOS kernel, Hyprland stable, shells, Stylix, SOPS. |
| [hosts/default.nix](hosts/default.nix) | Host registry. |
| [hosts/asura-xs15/default.nix](hosts/asura-xs15/default.nix) | Laptop host root and module list. |
| [hosts/asura-xs15/system](hosts/asura-xs15/system) | Laptop-only boot, hardware, filesystems, thermal, NBFC, power, secrets. |
| [hosts/asura-xs15/hyprland](hosts/asura-xs15/hyprland) | Laptop monitor/layout overrides. |
| [hosts/asura-xs15/shell/active-shell.nix](hosts/asura-xs15/shell/active-shell.nix) | Laptop active shell choice. |
| [hosts/asura-pc/default.nix](hosts/asura-pc/default.nix) | Desktop host root imported from `hyprNixos-main`, using shared laptop wiring. |
| [hosts/asura-pc/system](hosts/asura-pc/system) | PC-only AMD/NVIDIA/Broadcom, boot, filesystems, power, thermal, secrets. |
| [hosts/asura-pc/hyprland](hosts/asura-pc/hyprland) | PC monitor/layout overrides. |
| [hosts/asura-pc/shell/active-shell.nix](hosts/asura-pc/shell/active-shell.nix) | PC active shell choice. |
| [modules/shared](modules/shared) | Shared NixOS apps, services, users, nix policy, packages. |
| [modules/desktop](modules/desktop) | Shared display manager, theme, browser, XDG, wallpaper backend. |
| [modules/hardware/common.nix](modules/hardware/common.nix) | Shared hardware baseline only. |
| [modules/shells](modules/shells) | Shared shell enablement and switcher modules. |
| [home](home) | Shared Home Manager base and host overrides. |
| [home/desktop/hyprland](home/desktop/hyprland) | Shared Hyprland config, bindings, animations. |
| [shells/waybar](shells/waybar) | One shared Waybar config. |
| [shells/walker](shells/walker) | Shared Walker config root. |
| [shells/noctalia](shells/noctalia) | Shared Noctalia config, activated only when selected. |
| [shells/vibeshell](shells/vibeshell) | One shared VibeShell/Quickshell default config; no profiles. |
| [packages/skwd-wall](packages/skwd-wall) | Active shared wallpaper backend adapter. |
| [packages/vibewallREzero](packages/vibewallREzero) | Disabled for now; `skwd-wall` is active. |
| [docs/VALIDATION.md](docs/VALIDATION.md) | Extra validation and repo-safety checks. |
| [STRUCTURE.md](STRUCTURE.md) | Full tree overview. |

## Rules

- Shared apps, Hyprland bindings, animations, themes, Waybar, Walker, Noctalia, VibeShell, and `skwd-wall` stay in shared folders.
- Host-only hardware, kernel, power, thermal, filesystems, secrets, monitor layout, and active shell choice stay under `hosts/<host>/`.
- Laptop config remains the source of truth for shared wiring.
- Do not reintroduce removed shell experiments unless explicitly requested.
- Do not commit raw secrets, tokens, private keys, browser profiles, or local memory databases.
