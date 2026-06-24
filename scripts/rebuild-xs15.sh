#!/usr/bin/env bash
# Shared script: switch XS15 only after test-xs15.sh succeeds.
set -euo pipefail

/etc/nixos/scripts/test-xs15.sh
sudo nixos-rebuild switch --flake /etc/nixos#asura-xs15
