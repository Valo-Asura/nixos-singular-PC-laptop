# Hyprland Quickshell Profiles

The old isolated MangoWM session has been removed from the active NixOS
configuration. The useful shell experiments are now switchable profiles for the
normal `Hyprland` session. VibeShell is the default shell; Noctalia remains the
secondary stable fallback.

## Paths

| Item | Path |
|---|---|
| Module | `/etc/nixos/asura-xs15/quickshell/default.nix` |
| Caelestia source | `/etc/nixos/asura-xs15/quickshell/profiles/caelestia` |
| Ricelin source | `/etc/nixos/asura-xs15/quickshell/profiles/ricelin` |
| Dotfiles source | `/etc/nixos/asura-xs15/quickshell/profiles/dotfiles` |
| Tide Island source | `/etc/nixos/asura-xs15/quickshell/profiles/tide-island` |
| VibeShell source | `/etc/nixos/asura-xs15/quickshell/profiles/vibeshell` |
| Nandoroid source | `/etc/nixos/asura-xs15/quickshell/profiles/nandoroid` |
| Waybar source | `/etc/nixos/asura-xs15/waybar` |
| Colorshell Ryo AGS shell | `/etc/nixos/asura-xs15/ags-v3-colorshell-ryo` |
| Runtime Caelestia path | `/etc/xdg/quickshell/caelestia` |
| Runtime Ricelin path | `/etc/xdg/quickshell/ricelin` |
| Runtime Dotfiles path | `/etc/xdg/quickshell/dotfiles` |
| Runtime Tide Island path | `/etc/xdg/quickshell/tide-island` |
| Runtime VibeShell path | `/etc/xdg/quickshell/vibeshell` |
| Runtime Waybar path | `/etc/xdg/waybar-asura` |

## Commands

```bash
asura-quickshell-switch status
asura-quickshell-switch autostart
asura-quickshell-switch vibeshell
asura-quickshell-switch noctalia
asura-quickshell-switch caelestia
asura-quickshell-switch ricelin
asura-quickshell-switch dotfiles
asura-quickshell-switch tide-island
asura-quickshell-switch nandoroid
asura-quickshell-switch waybar
asura-quickshell-switch colorshell-ryo
asura-quickshell-switch stop-quickshell
```

`asura-shell-launcher` opens the launcher for the selected profile. Bare
`SUPER_L`/`SUPER_R` release uses that helper. `SUPER+A` calls
`asura-shell-launcher /tools` for profile-aware quick actions.
`SUPER+Period` and `SUPER+SHIFT+E` still route emoji through the same helper.

## Proof

Live Hyprland proof screenshots:

| Profile | Screenshot |
|---|---|
| Dotfiles launcher | `screenshots/hyprland-dotfiles-quickshell-proof-20260619.png` |
| Ricelin launcher | `screenshots/hyprland-ricelin-launcher-proof-20260619.png` |
| Caelestia launcher | `screenshots/hyprland-caelestia-launcher-proof-20260619.png` |
| Tide Island control center | `screenshots/bench-shell-tide-island-working-20260619-113414.png` |
| Waybar vertical pill | `screenshots/waybar-vertical-pill-proof-20260619.png` |
| Waybar vertical crop | `screenshots/waybar-vertical-pill-crop-20260619.png` |
| VibeShell rest notch | `screenshots/vibeshell-rest-notch-20260621.png` |
| VibeShell hover morph | `screenshots/vibeshell-hover-morph-20260621.png` |
| VibeShell launcher via `asura-shell-launcher` | `screenshots/vibeshell-launcher-20260621.png` |
| VibeShell dashboard via `vibeshell run dashboard` | `screenshots/vibeshell-dashboard-20260621.png` |
| VibeShell power menu via `vibeshell run powermenu` | `screenshots/vibeshell-power-menu-20260621.png` |
| VibeShell live after boot QML fix | `screenshots/vibeshell-live-after-bootfix-20260623.png` |
| VibeShell final live check | `screenshots/vibeshell-live-final-20260623.png` |
| Colorshell Ryo runner/control surface | `screenshots/colorshell-ryo-still-works-20260621.png` |
| Noctalia restored after test | `screenshots/noctalia-restored-20260621.png` |

VibeShell is now the Ricelin-inspired morphing notch experiment: it keeps
VibeShell services while porting Ricelin liquid easing and the Ame pointer bead
into the center island. `vibeshell run dashboard` is a supported alias for the
dashboard surface.

## Safety

`noctalia.service` is configured with `KillMode=process` so stopping the shell
does not kill apps launched from the shell cgroup. The switcher refuses to stop
Noctalia if the live service still has the old `KillMode=control-group`; rebuild
first.

## Default

The default profile is VibeShell. Hyprland starts the saved shell profile with
`asura-quickshell-switch autostart`; when no state exists, the switcher chooses
VibeShell.

```bash
asura-quickshell-switch vibeshell
```

Noctalia is kept as the secondary stable fallback:

```bash
asura-quickshell-switch noctalia
```

`waybar` is a left vertical pill bar-only profile. Switching to it stops
Noctalia and the other optional shell processes, the same as the Quickshell
test profiles. Return to the full desktop shell with:

```bash
asura-quickshell-switch noctalia
```
