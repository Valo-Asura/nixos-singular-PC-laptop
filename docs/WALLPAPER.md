# Wallpaper Workflow

This system uses Noctalia as the active shell and keeps the wallpaper entry
point declarative through Home Manager.

## Keybinds

| Keybind | Action |
|---|---|
| `SUPER+W` | Open wallpaper workflow |
| `SUPER+SHIFT+W` | Open wallpaper workflow |
| `SUPER+P` | Display manager |
| `SUPER+SHIFT+P` | Restore/reload display layout |

`SUPER+W` runs:

```bash
asura-wallpaper-panel
```

The wrapper is intentionally Noctalia-only because `skwd-wall` is not available
on this host:

```bash
noctalia msg panel-toggle wallpaper
```

## Paths

| Path | Purpose |
|---|---|
| `/home/asura/Pictures/Wallpapers` | Main wallpaper directory used by Noctalia settings |
| `/etc/nixos/asura-xs15/noctaliaShell/settings.toml` | Declarative Noctalia wallpaper and lockscreen settings |
| `/etc/nixos/asura-xs15/scripts/desktop-helpers.nix` | Declares `asura-wallpaper-panel` |
| `/etc/nixos/asura-xs15/hyprland/bindings.nix` | Nix-owned Hyprland keybind source |
| `/etc/nixos/screenshots/lockscreen.png` | Noctalia lockscreen wallpaper |

## Validate

```bash
command -v asura-wallpaper-panel
asura-wallpaper-panel
hyprctl binds | grep -F 'SUPER'
```

If Noctalia is running, the panel should open. If another wallpaper tool is
added later, change `asura-wallpaper-panel` in the repo instead of adding an
imperative desktop shortcut.
