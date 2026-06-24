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
# Validate both hosts without switching.
nix flake check --no-build /etc/nixos
nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel --no-link
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link

# Laptop rebuild: run on asura-xs15.
sudo nixos-rebuild test --flake /etc/nixos#asura-xs15
sudo nixos-rebuild boot --flake /etc/nixos#asura-xs15
sudo nixos-rebuild switch --flake /etc/nixos#asura-xs15

# Desktop rebuild: run on asura-pc.
sudo nixos-rebuild test --flake /etc/nixos#asura-pc
sudo nixos-rebuild boot --flake /etc/nixos#asura-pc
sudo nixos-rebuild switch --flake /etc/nixos#asura-pc

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

Clickable repo map. Each linked node opens the matching file or folder.

- [/etc/nixos](.) `# flake root`
  - [flake.nix](flake.nix) `# single flake; exports asura-xs15 and asura-pc`
  - [flake.lock](flake.lock) `# locked nixos-unstable, Hyprland stable, CachyOS kernel, shells`
  - [README.md](README.md) `# compact entrypoint and command list`
  - [STRUCTURE.md](STRUCTURE.md) `# fuller tree review`
  - [AGENTS.md](AGENTS.md) `# local agent rules for this repo`
  - [lib/](lib/) `# shared host helpers`
    - [lib/mkHost.nix](lib/mkHost.nix) `# common host constructor`
    - [lib/constants.nix](lib/constants.nix) `# shared constants`
  - [hosts/](hosts/) `# host-specific roots only`
    - [hosts/default.nix](hosts/default.nix) `# host registry used by flake.nix`
    - [hosts/asura-xs15/](hosts/asura-xs15/) `# laptop host; current source of truth`
      - [hosts/asura-xs15/default.nix](hosts/asura-xs15/default.nix) `# laptop imports and module list`
      - [hosts/asura-xs15/hardware-configuration.nix](hosts/asura-xs15/hardware-configuration.nix) `# generated laptop hardware config`
      - [hosts/asura-xs15/system/](hosts/asura-xs15/system/) `# laptop-only boot, kernel, thermal, NBFC, power, filesystems`
        - [hosts/asura-xs15/system/kernel.nix](hosts/asura-xs15/system/kernel.nix) `# CachyOS laptop kernel settings`
        - [hosts/asura-xs15/system/hardware.nix](hosts/asura-xs15/system/hardware.nix) `# laptop devices and drivers`
        - [hosts/asura-xs15/system/fan-control.nix](hosts/asura-xs15/system/fan-control.nix) `# laptop NBFC fan control`
        - [hosts/asura-xs15/system/secrets.nix](hosts/asura-xs15/system/secrets.nix) `# laptop SOPS wiring`
      - [hosts/asura-xs15/hyprland/](hosts/asura-xs15/hyprland/) `# laptop monitor/layout overrides`
        - [hosts/asura-xs15/hyprland/monitors.nix](hosts/asura-xs15/hyprland/monitors.nix) `# laptop display layout`
      - [hosts/asura-xs15/home/default.nix](hosts/asura-xs15/home/default.nix) `# laptop Home Manager override entry`
      - [hosts/asura-xs15/shell/active-shell.nix](hosts/asura-xs15/shell/active-shell.nix) `# laptop active shell choice`
    - [hosts/asura-pc/](hosts/asura-pc/) `# desktop host imported from hyprNixos-main`
      - [hosts/asura-pc/default.nix](hosts/asura-pc/default.nix) `# PC imports using shared wiring`
      - [hosts/asura-pc/hardware-configuration.nix](hosts/asura-pc/hardware-configuration.nix) `# generated PC hardware config`
      - [hosts/asura-pc/system/](hosts/asura-pc/system/) `# PC-only boot, AMD/NVIDIA/Broadcom, filesystems, power`
        - [hosts/asura-pc/system/kernel.nix](hosts/asura-pc/system/kernel.nix) `# CachyOS PC kernel settings`
        - [hosts/asura-pc/system/hardware.nix](hosts/asura-pc/system/hardware.nix) `# PC devices and drivers`
        - [hosts/asura-pc/system/patches/](hosts/asura-pc/system/patches/) `# PC-only Broadcom patch`
        - [hosts/asura-pc/system/secrets.nix](hosts/asura-pc/system/secrets.nix) `# PC SOPS wiring`
      - [hosts/asura-pc/hyprland/](hosts/asura-pc/hyprland/) `# PC monitor/layout overrides`
        - [hosts/asura-pc/hyprland/monitors.nix](hosts/asura-pc/hyprland/monitors.nix) `# PC display layout`
      - [hosts/asura-pc/home/default.nix](hosts/asura-pc/home/default.nix) `# PC Home Manager override entry`
      - [hosts/asura-pc/shell/active-shell.nix](hosts/asura-pc/shell/active-shell.nix) `# PC active shell choice`
  - [modules/](modules/) `# shared NixOS modules`
    - [modules/shared/](modules/shared/) `# shared apps, services, users, nix policy, packages`
      - [modules/shared/packages.nix](modules/shared/packages.nix) `# common system packages`
      - [modules/shared/programs.nix](modules/shared/programs.nix) `# common program toggles`
      - [modules/shared/services.nix](modules/shared/services.nix) `# common services`
      - [modules/shared/nix.nix](modules/shared/nix.nix) `# Nix settings and caches`
    - [modules/desktop/](modules/desktop/) `# shared desktop stack`
      - [modules/desktop/display-manager.nix](modules/desktop/display-manager.nix) `# greetd and Hyprland session`
      - [modules/desktop/theming.nix](modules/desktop/theming.nix) `# Stylix/shared visual theme`
      - [modules/desktop/browser-theming.nix](modules/desktop/browser-theming.nix) `# browser theme integration`
      - [modules/desktop/wallpaper.nix](modules/desktop/wallpaper.nix) `# shared skwd-wall wallpaper backend`
    - [modules/hardware/common.nix](modules/hardware/common.nix) `# shared hardware baseline only`
    - [modules/shells/](modules/shells/) `# shell enablement and switching`
      - [modules/shells/switcher.nix](modules/shells/switcher.nix) `# asura-shell-switch`
      - [modules/shells/vibeshell.nix](modules/shells/vibeshell.nix) `# shared VibeShell module`
      - [modules/shells/noctalia.nix](modules/shells/noctalia.nix) `# Noctalia module; conditional when selected`
      - [modules/shells/waybar.nix](modules/shells/waybar.nix) `# shared Waybar module`
      - [modules/shells/walker.nix](modules/shells/walker.nix) `# shared Walker module`
  - [home/](home/) `# shared Home Manager config`
    - [home/default.nix](home/default.nix) `# Home Manager root`
    - [home/shared/](home/shared/) `# shared user apps, shell, browser, templates`
    - [home/browser/](home/browser/) `# Firefox, Chrome, Brave, Helium config`
    - [home/desktop/hyprland/](home/desktop/hyprland/) `# shared Hyprland config`
      - [home/desktop/hyprland/default.nix](home/desktop/hyprland/default.nix) `# Hyprland HM entry`
      - [home/desktop/hyprland/bindings.nix](home/desktop/hyprland/bindings.nix) `# shared keybindings`
      - [home/desktop/hyprland/animations.nix](home/desktop/hyprland/animations.nix) `# shared animation rules`
    - [home/desktop/walker/default.nix](home/desktop/walker/default.nix) `# shared Walker user config`
    - [home/programs/](home/programs/) `# shared terminal, git, tmux, neovim, scripts`
    - [home/shell/](home/shell/) `# shared shell UX`
      - [home/shell/default.nix](home/shell/default.nix) `# shell config entry`
      - [home/shell/quotes.nix](home/shell/quotes.nix) `# terminal quote set`
    - [home/host-overrides/](home/host-overrides/) `# small per-host Home Manager deltas`
  - [shells/](shells/) `# shared shell configs; no host profiles`
    - [shells/waybar/](shells/waybar/) `# one shared Waybar config`
    - [shells/walker/](shells/walker/) `# shared Walker config root`
    - [shells/noctalia/](shells/noctalia/) `# shared Noctalia config; dormant unless selected`
    - [shells/vibeshell/](shells/vibeshell/) `# one shared VibeShell/Quickshell default`
      - [shells/vibeshell/home.nix](shells/vibeshell/home.nix) `# VibeShell Home Manager installer`
      - [shells/vibeshell/config/Config.qml](shells/vibeshell/config/Config.qml) `# VibeShell config entry`
      - [shells/vibeshell/modules/](shells/vibeshell/modules/) `# VibeShell UI modules`
  - [packages/](packages/) `# local packages and wrappers`
    - [packages/default.nix](packages/default.nix) `# package set export`
    - [packages/skwd-wall/](packages/skwd-wall/) `# active shared wallpaper backend`
    - [packages/vibeshell/](packages/vibeshell/) `# VibeShell wrapper placeholder`
    - [packages/vibewallREzero/](packages/vibewallREzero/) `# disabled for now; skwd-wall is active`
    - [packages/wrappers/](packages/wrappers/) `# wrapper docs`
  - [assets/](assets/) `# shared images, icons, wallpapers, theme assets`
  - [screenshots/](screenshots/) `# current shell review screenshots`
  - [scripts/](scripts/) `# local rebuild and migration helpers`
    - [scripts/test-xs15.sh](scripts/test-xs15.sh) `# laptop test helper`
    - [scripts/rebuild-xs15.sh](scripts/rebuild-xs15.sh) `# laptop rebuild helper`
    - [scripts/check-host.sh](scripts/check-host.sh) `# host check helper`
  - [docs/](docs/) `# validation notes`
    - [docs/VALIDATION.md](docs/VALIDATION.md) `# repo and build validation checklist`

## Rules

- Shared apps, Hyprland bindings, animations, themes, Waybar, Walker, Noctalia, VibeShell, and `skwd-wall` stay in shared folders.
- Host-only hardware, kernel, power, thermal, filesystems, secrets, monitor layout, and active shell choice stay under `hosts/<host>/`.
- Laptop config remains the source of truth for shared wiring.
- Do not reintroduce removed shell experiments unless explicitly requested.
- Do not commit raw secrets, tokens, private keys, browser profiles, or local memory databases.
