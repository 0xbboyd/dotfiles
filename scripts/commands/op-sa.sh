#!/bin/bash

# Print the 1Password service account token to stdout.
# Fetches from the Employee vault on every call — nothing is cached on disk.
# Usage: export OP_SERVICE_ACCOUNT_TOKEN="$(op-sa)"
# Requires the 1Password desktop app to be running and unlocked.

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

TOKEN=$(op item get "1Password Service Account Token" --vault Employee --field credential --reveal 2>/dev/null) || {
  echo "error: token item not found or vault locked — run 'op-sa-setup' first" >&2
  exit 1
}
printf '%s\n' "$TOKEN"
