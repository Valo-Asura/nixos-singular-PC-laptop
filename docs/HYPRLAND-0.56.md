# Hyprland 0.56.0 adoption

Pinned in [flake.nix](../flake.nix) as `github:hyprwm/Hyprland/v0.56.0`.

Upstream release notes: [v0.56.0](https://github.com/hyprwm/Hyprland/releases/tag/v0.56.0)

## Config changes applied in this flake

| Area | Setting | Value | Why |
|---|---|---|---|
| Flake input | `hyprland` | `v0.56.0` | Stable 0.56 compositor + matching XDPH |
| `cursor` | `no_hardware_cursors` | `2` (auto) | 0.56 default; disables HW cursors only when needed |
| `render` | `direct_scanout` | `2` (auto) | Lets Hyprland pick direct scanout when safe |
| `render` | `cm_auto_hdr` | `1` | Keep upstream HDR auto-switch default explicit |
| `master` | `focus_master_on_close` | `true` | Focus master after closing a tiled window |
| `group` | `groupbar.disable_when_only` | `true` | Hide group bar for single-window groups |
| `decoration` | `motion_blur.enabled` | `false` | Opt-in effect; left off for latency/VRAM |
| `decoration` | `motion_blur.samples` | `7` | Ready if motion blur is enabled later |
| `windowrule` | `no_auto_hdr 1` | `mpv`, `obs`, `gamescope`, Steam titles | Avoid HDR mode flips in media/gaming apps |
| `asura-monitor-guard` | reload path | `hyprctl config full-reload` | Ground-up reload added in 0.56 (#14748) |
| `asura-game-mode` off | reload path | `hyprctl config full-reload` | Same as monitor guard; falls back to `reload` |

Files touched:

- [home/desktop/hyprland/default.nix](../home/desktop/hyprland/default.nix)
- [home/programs/scripts/modules/desktop-helpers.nix](../home/programs/scripts/modules/desktop-helpers.nix)
- [modules/shells/switcher.nix](../modules/shells/switcher.nix)

## Automatic upstream fixes (no config required)

These ship with 0.56 and benefit both `asura-pc` and `asura-xs15`:

- Fullscreen / focus regressions (#15226, #15137, #14387)
- Monitor hotplug + DPMS (#14818, #15316, #15322)
- Pointer lock / gamescope dragging (#15165)
- XWayland configure loops (#15280, #15336)
- Layer surface focus restore after panel close (#15419)
- VRR runtime refresh (#14744)
- Submap / mouse bind fixes (#15060, #14856, #15213)
- Renderer damage, HDR blur, and scanout safety fixes (#15371, #14986, #14987)
- SHM cursor / protocol null-deref hardening (#15399, #15275, #15433)

## Not enabled yet

| Feature | Reason |
|---|---|
| `decoration.motion_blur.enabled = true` | Extra GPU cost; enable manually if wanted |
| Lua config migration | Flake stays on `configType = "hyprlang"` |
| Scrolling layout `inhibit_scroll` / `fit_into_view` | Not using scrolling layout |
| Interactive `hyprctl` Lua REPL | Debugging tool only |
| `render:tonemap` tuning | No local HDR workflow yet |
| `stableid:` window selectors | Add per-app when a rule needs stable matching |

## Post-switch checks

```bash
nix eval --raw /etc/nixos#nixosConfigurations.asura-pc.config.programs.hyprland.package.version
hyprctl version
hyprctl getoption cursor:no_hardware_cursors
hyprctl getoption render:direct_scanout
hyprctl getoption master:focus_master_on_close
hyprctl getoption decoration:motion_blur:enabled
hyprctl config full-reload
```

Expected:

- Package version starts with `0.56`
- `cursor:no_hardware_cursors` → `int: 2`
- `render:direct_scanout` → `int: 2`
- `master:focus_master_on_close` → `int: 1`
- `decoration:motion_blur:enabled` → `int: 0`
- `hyprctl config full-reload` exits 0

## Rollback

```bash
# In flake.nix
hyprland.url = "github:hyprwm/Hyprland/v0.55.4";

nix flake lock --update-input hyprland
sudo nixos-rebuild switch --flake /etc/nixos#asura-pc
```

Revert the config keys above if cursor or scanout behavior regresses on your hardware.
