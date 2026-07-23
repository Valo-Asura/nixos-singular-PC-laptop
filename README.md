# Asura NixOS

Single `/etc/nixos` flake for the laptop and desktop.

## Current State

| Area | Value |
|---|---|
| Repo | `Valo-Asura/nixos-singular-PC-laptop` |
| Hosts | `asura-xs15`, `asura-pc` |
| NixOS input | `nixos-unstable` / `26.11.20260616.567a49d` |
| Hyprland | stable `v0.56.0` from the official Hyprland flake ([adoption notes](docs/HYPRLAND-0.56.md)) |
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
  - [STRUCTURE.md](STRUCTURE.md) `# full clickable tree map`
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
      - [modules/desktop/display-manager.nix](modules/desktop/display-manager.nix) `# greetd, Hyprland, BSPWM fallback, Qtile`
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
      - [shells/vibeshell/shell.qml](shells/vibeshell/shell.qml) `# Quickshell entrypoint`
      - [shells/vibeshell/cli.sh](shells/vibeshell/cli.sh) `# VibeShell CLI wrapper`
      - [shells/vibeshell/config/Config.qml](shells/vibeshell/config/Config.qml) `# VibeShell config entry`
      - [shells/vibeshell/modules/](shells/vibeshell/modules/) `# VibeShell UI modules`
  - [packages/](packages/) `# local packages and wrappers`
    - [packages/default.nix](packages/default.nix) `# package set export`
    - [packages/skwd-wall/](packages/skwd-wall/) `# active shared wallpaper backend`
    - [packages/vibeshell/](packages/vibeshell/) `# VibeShell package helpers`
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

---

## Asura XS15 (Colorful XS) Laptop Tweaks, Workarounds & Inventory

Host: **Colorful X15 AT 22 / XS 22** (`asura-xs15`). Laptop-specific configs live in [hosts/asura-xs15/](hosts/asura-xs15/).

### 1. Fan & Thermal Control Stack
- **NBFC Stack**: Pinned `nbfc-linux` 0.5.2 and custom `nbfc-gtk` 0.4.1 wrapped with `GI_TYPELIB_PATH` to prevent GTK typelib launch failures (`docs/VALIDATION.md`).
- **Declarative EC Map (`/etc/nbfc/Colorful X15 AT 22.json`)**: 2 fans configured:
  - **CPU Fan**: Read register `207`, Write register `231`.
  - **GPU Fan**: Read register `208`, Write register `232`.
  - `MaxSpeed=255`, `CriticalTemp=72`, manual override write `Register=44 Value=8`.
- **Sensor Quirk**: Both fans use `@CPU` sensors only because NBFC-Linux exposes no `@GPU` hwmon sensor on this laptop EC.
- **GPU Fan Readback Quirk**: EC register `208` readback is unreliable (stays low/negative live); verification tools check Target Fan Speed + physical airflow.
- **EC Access & State Cleanup**: `ec_sys` kernel module with `write_support=1`; debugfs mounted in `nbfc` preStart. Wipes `/var/lib/nbfc/state.json` if fan count ≠ 2 to prevent stale state bugs.
- **Emergency Thermal Guard (`asura-thermal-guard`)**: Forces 100% fan speed if coretemp max reaches `≥88°C`, returning to auto curve at `≤72°C`.
- **Thermals & tuned**: `thermald` enabled with `coretemp` and `acpi_enforce_resources=lax`. TLP, `auto-cpufreq`, and `power-profiles-daemon` are force-disabled to avoid split ownership. Custom TuneD profiles:
  - `asura-xs15-balanced`: EPP `balance_power`.
  - `asura-xs15-performance`: EPP `balance_performance`.
  - `asura-xs15-balanced-battery`: EPP `balance_power`, boost disabled on battery, panel power savings.

### 2. NVIDIA Hybrid Graphics & Power Optimizations
- **PRIME Offload Mode**: Intel iGPU (`PCI:0:2:0`) handles internal display panel; dGPU (NVIDIA RTX 3050 Laptop `PCI:1:0:0`) runs on demand via `enableOffloadCmd`.
- **Runtime Power Management & Deep Sleep (RTD3)**: `powerManagement.enable = true` and `hardware.nvidia.powerManagement.finegrained = true` enable RTD3 power gating so the RTX 3050 sleeps when unused.
- **System Monitor dGPU Wake Fix**: `shells/vibeshell/scripts/system_monitor.py` discovers NVIDIA PCI paths dynamically and bypasses `nvidia-smi` queries when the GPU is suspended. Prevents micro-stutter and allows Intel CPU cores to drop to deep C10 sleep.
- **No Early NVIDIA Load / Boot Hang Prevention**: NVIDIA modules strictly forbidden in initrd (`boot.initrd.kernelModules`) and early kernel modules. Declarative empty stubs placed at `/etc/modules-load.d/nvidia*.conf` to prevent early load boot hangs.
- **Delayed Persistenced Service**: `nvidiaPersistenced = true` enabled for NVML/monitor compatibility, but `wantedBy = []` removed. Started 12s after boot via `nvidia-persistenced-delayed.timer` to avoid blocking `graphical.target`.
- **Rescue Specialisation (`rescue-no-nvidia`)**: Dedicated boot entry in systemd-boot blacklisting NVIDIA modules, booting multi-user target without Plymouth.
- **Polkit & App GPU Pinning**: `hyprpolkitagent` configured with `VK_LOADER_DRIVERS_DISABLE=*nvidia*` and Mesa drivers to avoid dGPU wakeups. WhatsApp Web wrapper forces `DRI_PRIME=0`, `__NV_PRIME_RENDER_OFFLOAD=0`, Mesa EGL + Intel Vulkan ICD, and disables WebGPU/Vulkan to keep dGPU asleep. X11 fallback terminal greeter also pinned to iGPU.

### 3. Boot, Dual-Boot Hygiene & Secure Boot
- **Systemd-Boot Choice**: Declarative systemd-boot forced (`timeout=12`, `editor=false`, `consoleMode=max`, `configLimit=7`). Lanzaboote removed; PC uses Limine+SB while laptop uses systemd-boot with `sbctl` helper.
- **Windows Dual-Boot Sync**: Shares ESP PARTUUID `ea0c3f00-a433-4db6-b494-b982ec40415b`. `windowsEspPartUuid` set matching Linux. Declaratively chainloads `/EFI/Microsoft/Boot/bootmgfw.efi` without remounting ESP. `rebootForBitlocker = false`. Auto-cleans stale Limine/Atlas boot entries.
- **Secure Boot & TPM**: `sbctl`, `efibootmgr`, and `tpm2-tools` included; optional key generation script triggered by `/etc/nixos/enable-sbctl-auto-create`.
- **Kernel Boot Parameters**: Quiet splash, `loglevel=0` (or `loglevel=4` with explicit unit status), `video=eDP-1:1920x1080@144`, `nowatchdog`, `nmi_watchdog=0`, `split_lock_detect=off`, `cryptomgr.notests` for low latency and panel mode initialization. Plymouth `circle_hud` boot theme.

### 4. Power & Battery Optimizations
- **Auto Profile Switching**: Udev rule on `AC` state change (`KERNEL=="AC"`) automatically switches TuneD profile (`asura-xs15-balanced` on AC vs `asura-xs15-balanced-battery` on battery).
- **Video Wallpaper Battery Guard**: Timer and startup check suspend video wallpapers (`mpvpaper` / live wallpapers) when running on battery to save power and heat.
- **Storage & RAM Tuning**: zram compressed swap sized to 25% of 16GB RAM with zstd compression. NVMe queue settings (`read_ahead_kb=128`, `nr_requests=1024`, `noatime`, `lazytime`) to reduce write latency and SSD wear.

### 5. Audio, Input & Display Quirks
- **Audio Mic Quirk**: Kernel module option `snd-hda-intel model=dell-headset-multi` to fix ALC256 pin-sensing for internal and headset combo jacks.
- **EasyEffects Background Service**: Systemd user service running in background mode (`--service-mode --hide-window`) bound to PipeWire/WirePlumber to eliminate GUI footprint on boot.
- **144Hz Panel & Touchpad UX**: Internal 144Hz panel forced via kernel params and Hyprland config (`eDP-1:1920x1080@144`). Wayland 3/4-finger workspace gestures, touchpad natural scroll on Wayland, DWT off on X11 fallback, `caps:escape` mapping in XKB.
- **OBS Virtual Camera**: `v4l2loopback` configured with `video_nr=9` as "OBS Virtual Camera".

### 6. Networking, Wi-Fi & Systemd Session Deadlock Tweaks
- **Intel Alder Lake-P Wi-Fi**: `wpa_supplicant` backend forced for Intel Wi-Fi NIC with `powersave = false`, permanent MAC address, and disabled scan rand MAC to prevent drops. `NetworkManager-wait-online` disabled to eliminate boot delay. Activation script auto-pins 5GHz band on dual-band SSIDs.
- **Systemd User Session Deadlock Fix**: Set `security.pam.services.systemd-user.startSession = false` and explicitly set `XDG_RUNTIME_DIR=/run/user/%i` to prevent systemd-user from deadlocking when `pam_systemd` opens duplicate logind sessions (fixing 90s boot stalls and broken rebuild reloads). `user@.service` `TimeoutStartSec=25s`.
- **Noctalia NetworkManager Refresh**: Oneshot service `noctalia-networkmanager-refresh` runs post-NetworkManager restart to refresh network status for Noctalia shell UI.

### 7. Desktop Shell, Apps & Low-Idle Optimizations
- **VibeShell / Quickshell Idle Fix**: Disabled continuous QML charging battery animations while notch is collapsed. Drops CPU usage from 25–29% down to 2.7–2.9% at idle. Clamped bar height, 16MB QML heap, 3s file-transfer check interval.
- **Window Rules & File Managers**: GTK/portal file pickers aligned to 1100x720 geometry. PCManFM-Qt is primary file manager; Xarchiver is default archive handler for zip/tar/7z/zstd.
- **Super Productivity Bridge**: VibeShell dashboard Super Productivity strip integration with automated notes exporter (`vibeshell-notes-export.json/.md`).
- **Screenshots**: Independent `asura-screenshot` helper (`grim`+`slurp`+`wl-copy`) bypasses shell IPC so screenshots capture full UI across Noctalia, Waybar, and VibeShell setups.
- **XDM & Phone Link**: Fixed XDM GTK wrapper with GDK pixbuf librsvg loader export for SVG icon rendering without crashing. KDE Connect paired with `hypr-kdeconnect-fix` portal bridge for Wayland phone-to-laptop remote cursor control.

### 8. Planned & Future Laptop Enhancements
- **Durable AI Memory Sync**: Maintain system facts in `/etc/nixos/home/aimemory.nix` and `docs/XS15-HARDWARE.md`.
- **Dynamic Fan Profile Selector**: Future VibeShell/Noctalia desktop widget to toggle NBFC modes (Silent, Balanced, Turbo) without terminal editing.
- **Enhanced Thermal OSD**: Visual desktop notifications when `asura-thermal-guard` engages emergency 100% fan override.
- **Local AI Image Gen (RTX 3050 4GB)**: Continued optimization of Forge WebUI (SD1.5 / Realistic Vision) and `stable-diffusion.cpp` (z_image_turbo + Qwen3-4B text encoder) scripts for sub-15s generations within 4GB VRAM limit.

