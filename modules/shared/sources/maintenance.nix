# Shared module: Nix store maintenance, generation retention, TRIM, and low-priority rebuild helpers.
{
  lib,
  pkgs,
  ...
}:

let
  generationLimit = 7;
  baseSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  baseTrustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSBrg="
  ];
in
{
  # Nix Configuration
  nix = {
    settings = {
      experimental-features = lib.mkForce [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true; # hard-link identical files on every build
      keep-outputs = false; # don't retain build outputs after GC
      keep-derivations = false; # don't retain .drv files after GC
      min-free = 2 * 1024 * 1024 * 1024;
      max-free = 8 * 1024 * 1024 * 1024;

      # ── Rebuild responsiveness fix ──────────────────────────────────
      # Root cause of desktop freezes during nixos-rebuild:
      #   max-jobs = auto  → 12 parallel build jobs on this 12-thread CPU
      #   cores    = 0     → each job is given ALL cores (also 12)
      # Together this means every core is fully saturated by build
      # workers; the desktop compositor/input gets starved of CPU time.
      #
      # Fix: cap at 6 jobs × 4 cores each. scx_lavd + ananicy handle
      # real-time prioritisation on top. Raise temporarily if needed:
      #   sudo nixos-rebuild switch --option max-jobs 10
      max-jobs = 6;
      cores = 4;

      # Reduce sandbox /dev/shm from the default 50% (~8 GB) to 25% (~4 GB).
      # Heavy Rust/C++ builds can fill shm and cause OOM-adjacent stalls.
      sandbox-dev-shm-size = "25%";

      # Allow builds to use binary cache before falling back to source.
      fallback = true;

      # Shared cache policy. Force the list so NixOS defaults and host modules
      # do not merge duplicate cache.nixos.org entries or stale cache keys.
      substituters = lib.mkForce baseSubstituters;
      trusted-public-keys = lib.mkForce baseTrustedPublicKeys;
    };
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
    optimise.automatic = true; # periodic store optimisation pass
    optimise.dates = [ "daily" ];
    optimise.persistent = false; # do not catch up store optimisation during first login
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
      persistent = false; # do not run missed GC immediately at boot
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-storage-clean" ''
      set -euo pipefail

      days="''${1:-3d}"
      keep="''${ASURA_GENERATION_LIMIT:-${toString generationLimit}}"

      prune_profile() {
        profile="$1"
        [ -e "$profile" ] || return 0
        echo "Pruning $profile to the newest $keep generations"
        ${pkgs.nix}/bin/nix-env --profile "$profile" --delete-generations "+$keep" || true
      }

      echo "User GC: deleting generations older than $days"
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than "$days"

      prune_profile /nix/var/nix/profiles/system
      prune_profile /nix/var/nix/profiles/per-user/root/profile
      prune_profile /home/asura/.local/state/nix/profiles/home-manager

      if [ -L /etc/nixos/result ]; then
        echo "Removing stale /etc/nixos/result GC root"
        rm -f /etc/nixos/result
      fi

      if command -v sudo >/dev/null 2>&1; then
        echo "System GC: sudo may ask for your password"
        sudo nix-collect-garbage --delete-older-than "$days"
      fi

      echo "Optimising store links: sudo may ask for your password"
      sudo ${pkgs.nix}/bin/nix-store --optimise
    '')

    # ── Desktop-safe rebuild wrapper ──────────────────────────────────
    # Runs nixos-rebuild at the lowest scheduler priority so the desktop
    # stays responsive during a switch/boot/test.
    # All extra args pass through to nixos-rebuild unchanged.
    #
    # Usage:
    #   nixos-rebuild-safe switch
    #   nixos-rebuild-safe switch --flake /etc/nixos#asura-xs15
    (pkgs.writeShellScriptBin "nixos-rebuild-safe" ''
      set -euo pipefail

      echo "[nixos-rebuild-safe] Running rebuild with reduced CPU/IO priority..."
      echo "  max-jobs=6  cores=4  nice=15  ionice=idle  MAKEFLAGS=-j6"
      echo ""

      # MAKEFLAGS caps linker/compiler parallelism inside each sandbox;
      # without this, Rust link steps can spike to all 12 threads even
      # when nix caps max-jobs.
      export MAKEFLAGS="-j6"
      export CARGO_BUILD_JOBS="6"

      exec ${pkgs.util-linux}/bin/ionice -c 3 \
        ${pkgs.coreutils}/bin/nice -n 15 \
        sudo nixos-rebuild "$@" \
          --option max-jobs 6 \
          --option cores 4 \
          --option sandbox-dev-shm-size "25%"
    '')
  ];

  boot.tmp.cleanOnBoot = true;
  services.fstrim.enable = true;
  services.journald.extraConfig = ''
    SystemMaxUse=256M
    RuntimeMaxUse=128M
    MaxRetentionSec=14day
    Compress=yes
  '';

  system.activationScripts.pruneNixGenerations.text = ''
    keep=${toString generationLimit}
    for profile in \
      /nix/var/nix/profiles/system \
      /nix/var/nix/profiles/per-user/root/profile \
      /home/asura/.local/state/nix/profiles/home-manager
    do
      [ -e "$profile" ] || continue
      ${pkgs.nix}/bin/nix-env --profile "$profile" --delete-generations "+$keep" || true
    done
  '';

  # Maintenance tasks should never compete with the desktop.
  systemd.services = {
    asura-prune-nix-generations = {
      description = "Keep only the newest ${toString generationLimit} NixOS/Home Manager generations";
      path = with pkgs; [
        nix
        coreutils
      ];
      script = ''
        set -euo pipefail

        keep=${toString generationLimit}
        for profile in \
          /nix/var/nix/profiles/system \
          /nix/var/nix/profiles/per-user/root/profile \
          /home/asura/.local/state/nix/profiles/home-manager
        do
          [ -e "$profile" ] || continue
          ${pkgs.nix}/bin/nix-env --profile "$profile" --delete-generations "+$keep" || true
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
        CPUSchedulingPolicy = "idle";
        CPUWeight = 10;
      };
    };

    nix-daemon = {
      # Restart after nix.conf-affecting changes so rebuilds do not keep using
      # stale trust keys from the previous generation.
      restartTriggers = [
        (pkgs.writeText "asura-nix-daemon-cache-trigger" (
          builtins.toJSON {
            substituters = baseSubstituters;
            trustedPublicKeys = baseTrustedPublicKeys;
          }
        ))
      ];
    };

    nix-gc.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      CPUWeight = 10; # yield heavily to interactive tasks
    };
    nix-optimise.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "idle";
      CPUWeight = 10;
    };
    fstrim.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
    # Give nix-daemon a low cgroup CPU/IO weight so scx_lavd can throttle
    # rebuild workers whenever interactive apps need cores.
    # (default CPUWeight = 100; lower = yields more readily)
    nix-daemon.serviceConfig = {
      CPUWeight = 15; # was 20 — yield even harder
      IOWeight = 15;
      # Kernel memory pressure: constrain nix-daemon to 60% of RAM
      # before it starts blocking on allocation. Prevents desktop freeze
      # when many parallel builds allocate simultaneously.
      MemoryHigh = "60%";
      MemoryMax = "80%";
      MemorySwapMax = "2G";
    };
  };

  systemd.timers.asura-prune-nix-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = false;
      RandomizedDelaySec = "30m";
    };
  };

  # System Updates (disabled for flake-based system)
  system = {
    autoUpgrade.enable = false; # Use 'nix flake update' instead
    stateVersion = "25.11";
  };
}
