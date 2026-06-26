# Structure

Clickable repo map. Each linked node opens the matching file or folder.

- [/etc/nixos](.) `# flake root`
  - [flake.nix](flake.nix) `# single flake; exports asura-xs15 and asura-pc`
  - [flake.lock](flake.lock) `# locked nixos-unstable, Hyprland, CachyOS kernel, shell inputs`
  - [README.md](README.md) `# compact entrypoint, current state, commands`
  - [STRUCTURE.md](STRUCTURE.md) `# full clickable repo map`
  - [AGENTS.md](AGENTS.md) `# local agent rules for this repo`

- [lib/](lib/) `# shared host helpers`
  - [lib/mkHost.nix](lib/mkHost.nix) `# common host constructor`
  - [lib/constants.nix](lib/constants.nix) `# shared constants`

- [hosts/](hosts/) `# host-specific roots only`
  - [hosts/default.nix](hosts/default.nix) `# host registry used by flake.nix`
  - [hosts/asura-xs15/](hosts/asura-xs15/) `# laptop host; shared-source reference`
    - [hosts/asura-xs15/default.nix](hosts/asura-xs15/default.nix) `# laptop imports and module list`
    - [hosts/asura-xs15/hardware-configuration.nix](hosts/asura-xs15/hardware-configuration.nix) `# generated laptop hardware config`
    - [hosts/asura-xs15/system/](hosts/asura-xs15/system/) `# laptop-only boot, kernel, thermal, fan, power, filesystems`
      - [hosts/asura-xs15/system/boot.nix](hosts/asura-xs15/system/boot.nix) `# laptop boot, systemd-boot, Plymouth`
      - [hosts/asura-xs15/system/kernel.nix](hosts/asura-xs15/system/kernel.nix) `# laptop kernel choice`
      - [hosts/asura-xs15/system/hardware.nix](hosts/asura-xs15/system/hardware.nix) `# laptop devices and drivers`
      - [hosts/asura-xs15/system/performance.nix](hosts/asura-xs15/system/performance.nix) `# laptop-safe performance tuning`
      - [hosts/asura-xs15/system/thermal.nix](hosts/asura-xs15/system/thermal.nix) `# laptop thermal stack`
      - [hosts/asura-xs15/system/fan-control.nix](hosts/asura-xs15/system/fan-control.nix) `# laptop NBFC fan control`
      - [hosts/asura-xs15/system/power.nix](hosts/asura-xs15/system/power.nix) `# laptop battery/power tuning`
      - [hosts/asura-xs15/system/filesystems.nix](hosts/asura-xs15/system/filesystems.nix) `# laptop mounts and swap`
      - [hosts/asura-xs15/system/secrets.nix](hosts/asura-xs15/system/secrets.nix) `# laptop SOPS wiring`
    - [hosts/asura-xs15/hyprland/](hosts/asura-xs15/hyprland/) `# laptop monitor/layout overrides`
      - [hosts/asura-xs15/hyprland/monitors.nix](hosts/asura-xs15/hyprland/monitors.nix) `# laptop display layout`
      - [hosts/asura-xs15/hyprland/host.nix](hosts/asura-xs15/hyprland/host.nix) `# laptop-only Hyprland overrides`
    - [hosts/asura-xs15/home/default.nix](hosts/asura-xs15/home/default.nix) `# laptop Home Manager override entry`
    - [hosts/asura-xs15/shell/active-shell.nix](hosts/asura-xs15/shell/active-shell.nix) `# laptop active shell choice`
    - [hosts/asura-xs15/plymouth/](hosts/asura-xs15/plymouth/) `# laptop Plymouth assets`
    - [hosts/asura-xs15/secrets/](hosts/asura-xs15/secrets/) `# laptop encrypted secrets`

  - [hosts/asura-pc/](hosts/asura-pc/) `# desktop host imported from old PC config`
    - [hosts/asura-pc/README.md](hosts/asura-pc/README.md) `# PC-specific notes and rebuild commands`
    - [hosts/asura-pc/default.nix](hosts/asura-pc/default.nix) `# PC imports using shared wiring`
    - [hosts/asura-pc/hardware-configuration.nix](hosts/asura-pc/hardware-configuration.nix) `# generated PC hardware config`
    - [hosts/asura-pc/system/](hosts/asura-pc/system/) `# PC-only boot, AMD/NVIDIA/Broadcom, filesystems, power`
      - [hosts/asura-pc/system/boot.nix](hosts/asura-pc/system/boot.nix) `# PC bootloader, systemd-boot, stale entry cleanup`
      - [hosts/asura-pc/system/kernel.nix](hosts/asura-pc/system/kernel.nix) `# CachyOS PC kernel settings`
      - [hosts/asura-pc/system/hardware.nix](hosts/asura-pc/system/hardware.nix) `# PC devices and drivers`
      - [hosts/asura-pc/system/display.nix](hosts/asura-pc/system/display.nix) `# PC display/GPU display tuning`
      - [hosts/asura-pc/system/performance.nix](hosts/asura-pc/system/performance.nix) `# PC performance tuning`
      - [hosts/asura-pc/system/desktop-performance.nix](hosts/asura-pc/system/desktop-performance.nix) `# desktop responsiveness tuning`
      - [hosts/asura-pc/system/thermal.nix](hosts/asura-pc/system/thermal.nix) `# PC thermal services`
      - [hosts/asura-pc/system/power.nix](hosts/asura-pc/system/power.nix) `# PC power helpers`
      - [hosts/asura-pc/system/filesystems.nix](hosts/asura-pc/system/filesystems.nix) `# PC mounts, swap, Windows partitions`
      - [hosts/asura-pc/system/secrets.nix](hosts/asura-pc/system/secrets.nix) `# PC SOPS wiring`
      - [hosts/asura-pc/system/patches/](hosts/asura-pc/system/patches/) `# PC-only Broadcom kernel patch`
        - [hosts/asura-pc/system/patches/broadcom-sta-linux-7.1-cfg80211-wdev.patch](hosts/asura-pc/system/patches/broadcom-sta-linux-7.1-cfg80211-wdev.patch) `# Broadcom STA Linux 7.1 cfg80211 fix`
    - [hosts/asura-pc/hyprland/](hosts/asura-pc/hyprland/) `# PC monitor/layout overrides`
      - [hosts/asura-pc/hyprland/monitors.nix](hosts/asura-pc/hyprland/monitors.nix) `# PC display layout`
      - [hosts/asura-pc/hyprland/host.nix](hosts/asura-pc/hyprland/host.nix) `# PC-only Hyprland overrides`
    - [hosts/asura-pc/home/default.nix](hosts/asura-pc/home/default.nix) `# PC Home Manager override entry`
    - [hosts/asura-pc/shell/active-shell.nix](hosts/asura-pc/shell/active-shell.nix) `# PC active shell choice`
    - [hosts/asura-pc/plymouth/](hosts/asura-pc/plymouth/) `# PC Plymouth assets`
    - [hosts/asura-pc/secrets/](hosts/asura-pc/secrets/) `# PC encrypted secrets`

- [modules/](modules/) `# shared NixOS modules`
  - [modules/shared/](modules/shared/) `# shared apps, users, services, nix policy`
    - [modules/shared/nix.nix](modules/shared/nix.nix) `# Nix settings and caches`
    - [modules/shared/users.nix](modules/shared/users.nix) `# shared user/group/sudo setup`
    - [modules/shared/networking.nix](modules/shared/networking.nix) `# NetworkManager and firewall baseline`
    - [modules/shared/audio.nix](modules/shared/audio.nix) `# PipeWire audio stack`
    - [modules/shared/kdeconnect.nix](modules/shared/kdeconnect.nix) `# KDE Connect integration`
    - [modules/shared/packages.nix](modules/shared/packages.nix) `# common system packages`
    - [modules/shared/programs.nix](modules/shared/programs.nix) `# common program toggles`
    - [modules/shared/services.nix](modules/shared/services.nix) `# common services`
    - [modules/shared/gaming.nix](modules/shared/gaming.nix) `# shared gaming stack`
    - [modules/shared/android.nix](modules/shared/android.nix) `# adb, fastboot, MTP tooling`
    - [modules/shared/maintenance.nix](modules/shared/maintenance.nix) `# GC, optimize-store, fstrim`
    - [modules/shared/virtual-machines.nix](modules/shared/virtual-machines.nix) `# libvirt/QEMU baseline`
  - [modules/hardware/](modules/hardware/) `# reusable hardware baseline`
    - [modules/hardware/common.nix](modules/hardware/common.nix) `# shared hardware baseline only`
  - [modules/desktop/](modules/desktop/) `# shared desktop stack`
    - [modules/desktop/display-manager.nix](modules/desktop/display-manager.nix) `# greetd, Hyprland, BSPWM fallback, Qtile`
    - [modules/desktop/theming.nix](modules/desktop/theming.nix) `# Stylix/shared visual theme`
    - [modules/desktop/browser-theming.nix](modules/desktop/browser-theming.nix) `# browser theme integration`
    - [modules/desktop/xdg.nix](modules/desktop/xdg.nix) `# shared XDG defaults`
    - [modules/desktop/wallpaper.nix](modules/desktop/wallpaper.nix) `# active skwd-wall wallpaper backend`
  - [modules/shells/](modules/shells/) `# shell enablement and switching`
    - [modules/shells/switcher.nix](modules/shells/switcher.nix) `# asura-shell-switch`
    - [modules/shells/vibeshell.nix](modules/shells/vibeshell.nix) `# shared VibeShell module`
    - [modules/shells/noctalia.nix](modules/shells/noctalia.nix) `# Noctalia module; conditional when selected`
    - [modules/shells/waybar.nix](modules/shells/waybar.nix) `# shared Waybar module`
    - [modules/shells/walker.nix](modules/shells/walker.nix) `# shared Walker module`

- [home/](home/) `# shared Home Manager config`
  - [home/default.nix](home/default.nix) `# Home Manager root`
  - [home/application.nix](home/application.nix) `# shared desktop applications`
  - [home/aimemory.nix](home/aimemory.nix) `# shared AI memory wiring`
  - [home/shared/](home/shared/) `# shared user apps, shell, browser, templates`
    - [home/shared/apps.nix](home/shared/apps.nix) `# shared app package groups`
    - [home/shared/browser.nix](home/shared/browser.nix) `# shared browser wiring`
    - [home/shared/programs.nix](home/shared/programs.nix) `# shared user programs`
    - [home/shared/shell.nix](home/shared/shell.nix) `# shared shell UX`
    - [home/shared/ai-memory.nix](home/shared/ai-memory.nix) `# shared AI memory tools`
  - [home/browser/](home/browser/) `# Firefox, Chrome, Brave, Helium config`
    - [home/browser/default.nix](home/browser/default.nix) `# browser config root`
    - [home/browser/firefox.nix](home/browser/firefox.nix) `# Firefox config`
    - [home/browser/chrome.nix](home/browser/chrome.nix) `# Chrome config`
    - [home/browser/brave.nix](home/browser/brave.nix) `# Brave config`
    - [home/browser/helium.nix](home/browser/helium.nix) `# Helium config`
  - [home/desktop/](home/desktop/) `# shared desktop Home Manager modules`
    - [home/desktop/hyprland/](home/desktop/hyprland/) `# shared Hyprland config`
      - [home/desktop/hyprland/default.nix](home/desktop/hyprland/default.nix) `# Hyprland HM entry`
      - [home/desktop/hyprland/bindings.nix](home/desktop/hyprland/bindings.nix) `# shared keybindings`
      - [home/desktop/hyprland/animations.nix](home/desktop/hyprland/animations.nix) `# shared animation rules`
      - [home/desktop/hyprland/hyprlock.nix](home/desktop/hyprland/hyprlock.nix) `# Hyprlock config`
      - [home/desktop/hyprland/hypridle.nix](home/desktop/hyprland/hypridle.nix) `# Hypridle config`
      - [home/desktop/hyprland/polkitagent.nix](home/desktop/hyprland/polkitagent.nix) `# Polkit agent startup`
    - [home/desktop/walker/default.nix](home/desktop/walker/default.nix) `# shared Walker user config`
    - [home/desktop/hyprlock/default.nix](home/desktop/hyprlock/default.nix) `# lock screen module`
    - [home/desktop/hypridle/default.nix](home/desktop/hypridle/default.nix) `# idle daemon module`
    - [home/desktop/theming/default.nix](home/desktop/theming/default.nix) `# user theme module`
  - [home/programs/](home/programs/) `# shared terminal, git, tmux, neovim, scripts`
    - [home/programs/default.nix](home/programs/default.nix) `# shared programs entry`
    - [home/programs/terminal/default.nix](home/programs/terminal/default.nix) `# Foot/terminal config`
    - [home/programs/git/default.nix](home/programs/git/default.nix) `# Git config`
    - [home/programs/tmux/default.nix](home/programs/tmux/default.nix) `# tmux config`
    - [home/programs/neovim/default.nix](home/programs/neovim/default.nix) `# Neovim config`
    - [home/programs/scripts/default.nix](home/programs/scripts/default.nix) `# user helper scripts`
    - [home/programs/fastfetch/default.nix](home/programs/fastfetch/default.nix) `# Fastfetch config`
  - [home/shell/](home/shell/) `# shared shell UX`
    - [home/shell/default.nix](home/shell/default.nix) `# shell config entry`
    - [home/shell/quotes.nix](home/shell/quotes.nix) `# terminal quote set`
  - [home/host-overrides/](home/host-overrides/) `# small per-host Home Manager deltas`
    - [home/host-overrides/asura-xs15.nix](home/host-overrides/asura-xs15.nix) `# laptop HM imports`
    - [home/host-overrides/asura-pc.nix](home/host-overrides/asura-pc.nix) `# PC HM imports`

- [shells/](shells/) `# shared shell configs; no host profiles`
  - [shells/waybar/](shells/waybar/) `# one shared Waybar config`
    - [shells/waybar/config.jsonc](shells/waybar/config.jsonc) `# Waybar layout`
    - [shells/waybar/style.css](shells/waybar/style.css) `# Waybar CSS`
    - [shells/waybar/scripts/](shells/waybar/scripts/) `# Waybar helper scripts`
  - [shells/walker/](shells/walker/) `# shared Walker config root`
    - [shells/walker/README.md](shells/walker/README.md) `# Walker notes`
  - [shells/noctalia/](shells/noctalia/) `# shared Noctalia config`
    - [shells/noctalia/settings.toml](shells/noctalia/settings.toml) `# Noctalia settings`
    - [shells/noctalia/state.toml](shells/noctalia/state.toml) `# Noctalia state`
    - [shells/noctalia/foot.ini](shells/noctalia/foot.ini) `# Noctalia terminal theme`
  - [shells/vibeshell/](shells/vibeshell/) `# one shared VibeShell/Quickshell default`
    - [shells/vibeshell/README.md](shells/vibeshell/README.md) `# VibeShell notes`
    - [shells/vibeshell/shell.qml](shells/vibeshell/shell.qml) `# Quickshell entrypoint`
    - [shells/vibeshell/home.nix](shells/vibeshell/home.nix) `# VibeShell Home Manager installer`
    - [shells/vibeshell/cli.sh](shells/vibeshell/cli.sh) `# VibeShell CLI wrapper`
    - [shells/vibeshell/binds.json](shells/vibeshell/binds.json) `# VibeShell keybind definitions`
    - [shells/vibeshell/system.json](shells/vibeshell/system.json) `# VibeShell system config seed`
    - [shells/vibeshell/config/](shells/vibeshell/config/) `# VibeShell config engine`
      - [shells/vibeshell/config/Config.qml](shells/vibeshell/config/Config.qml) `# VibeShell config singleton`
      - [shells/vibeshell/config/defaults/bar.js](shells/vibeshell/config/defaults/bar.js) `# bar defaults`
      - [shells/vibeshell/config/defaults/theme.js](shells/vibeshell/config/defaults/theme.js) `# theme defaults`
    - [shells/vibeshell/modules/](shells/vibeshell/modules/) `# VibeShell UI modules`
      - [shells/vibeshell/modules/bar/Bar.qml](shells/vibeshell/modules/bar/Bar.qml) `# top bar shell`
      - [shells/vibeshell/modules/bar/BarBg.qml](shells/vibeshell/modules/bar/BarBg.qml) `# bar background and tint`
      - [shells/vibeshell/modules/notch/Notch.qml](shells/vibeshell/modules/notch/Notch.qml) `# notch container`
      - [shells/vibeshell/modules/notch/NotchLauncherView.qml](shells/vibeshell/modules/notch/NotchLauncherView.qml) `# notch app launcher`
      - [shells/vibeshell/modules/lockscreen/LockScreen.qml](shells/vibeshell/modules/lockscreen/LockScreen.qml) `# VibeShell lock UI`
      - [shells/vibeshell/modules/theme/Styling.qml](shells/vibeshell/modules/theme/Styling.qml) `# styled rect theme resolution`
    - [shells/vibeshell/assets/](shells/vibeshell/assets/) `# VibeShell assets, colors, presets`
      - [shells/vibeshell/assets/presets/Default/bar.json](shells/vibeshell/assets/presets/Default/bar.json) `# default bar preset`
      - [shells/vibeshell/assets/presets/Default/theme.json](shells/vibeshell/assets/presets/Default/theme.json) `# default theme preset`
    - [shells/vibeshell/scripts/](shells/vibeshell/scripts/) `# VibeShell helper scripts`

- [packages/](packages/) `# local packages and wrappers`
  - [packages/default.nix](packages/default.nix) `# package set export`
  - [packages/skwd-wall/](packages/skwd-wall/) `# active shared wallpaper backend`
  - [packages/vibeshell/](packages/vibeshell/) `# VibeShell package wrapper`
  - [packages/vibewallREzero/](packages/vibewallREzero/) `# present but disabled; skwd-wall is active`
  - [packages/wrappers/](packages/wrappers/) `# wrapper docs`

- [assets/](assets/) `# shared images, icons, wallpapers, theme assets`
- [screenshots/](screenshots/) `# shell review screenshots`
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

## Validation

```bash
nix flake check --no-build /etc/nixos
nix build /etc/nixos#nixosConfigurations.asura-xs15.config.system.build.toplevel --no-link
nix build /etc/nixos#nixosConfigurations.asura-pc.config.system.build.toplevel --no-link
```
