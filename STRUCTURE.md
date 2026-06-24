# /etc/nixos Target Structure

Active host: `hosts/asura-xs15`

Future host: `hosts/asura-pc` placeholder only

The flake imports the target tree below. Legacy root-level shell/profile trees are removed.

```text
/etc/nixos
|-- flake.nix                  # single flake; exports asura-xs15 only
|-- hosts/
|   |-- default.nix            # host registry; asura-pc not exported yet
|   |-- asura-xs15/            # laptop-specific implementation
|   |   |-- default.nix        # XS15 host module root
|   |   |-- hardware-configuration.nix
|   |   |-- system/            # laptop-only kernel, power, thermal, NBFC, filesystems, secrets
|   |   |-- hyprland/          # laptop-only monitor layout
|   |   |-- shell/             # laptop-only active shell choice
|   |   |-- home/              # laptop-only Home Manager overrides
|   |   |-- assets/            # laptop-local assets kept with host
|   |   `-- secrets/           # laptop-local secret material
|   `-- asura-pc/              # placeholder; implement later
|-- modules/
|   |-- shared/                # shared NixOS apps, services, packages, users, nix policy
|   |-- desktop/               # shared display manager, theme, browser, XDG, skwd-wall
|   |-- hardware/              # shared hardware baseline only
|   `-- shells/                # shared shell modules and switcher
|-- home/
|   |-- shared/                # shared Home Manager apps, browsers, shell, editors
|   |-- desktop/               # shared Hyprland, bindings, animations, theming, Walker
|   `-- host-overrides/        # placeholders for per-host Home Manager overrides
|-- shells/
|   |-- waybar/                # one shared Waybar config
|   |-- walker/                # shared Walker config root
|   |-- noctalia/              # shared Noctalia config
|   `-- vibeshell/             # one shared VibeShell/Quickshell default config; no profiles
|-- packages/
|   |-- skwd-wall/             # active wallpaper backend adapter
|   |-- vibewallREzero/        # disabled for now; skwd-wall is active.
|   |-- vibeshell/             # placeholder; wrapper lives in modules/shells/vibeshell.nix
|   `-- wrappers/              # wrapper package notes
|-- assets/                    # shared theme/wallpaper assets
|-- lib/                       # shared constants and host constructor helpers
`-- scripts/                   # safe test/rebuild/check helpers
```

Shell switcher supports only:

```text
waybar
noctalia
vibeshell
```

Validation target:

```sh
sudo nixos-rebuild test --flake /etc/nixos#asura-xs15
sudo nixos-rebuild switch --flake /etc/nixos#asura-xs15
```
