#!/usr/bin/env bash
# Shared script: build/test the active XS15 flake target without switching first.
set -euo pipefail

sudo nixos-rebuild test --flake /etc/nixos#asura-xs15
