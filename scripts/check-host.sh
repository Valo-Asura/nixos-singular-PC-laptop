#!/usr/bin/env bash
# Shared script: evaluate one exported NixOS host target.
set -euo pipefail

host="${1:-asura-xs15}"
nix eval "/etc/nixos#nixosConfigurations.${host}.config.networking.hostName"
