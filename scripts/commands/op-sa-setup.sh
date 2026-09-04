#!/bin/bash

# One-time setup: store the 1Password service account token in the Employee vault.
# Prompts for the token with hidden input and validates it BEFORE storing, so a
# bad paste never lands in the vault. The token never touches disk or history.
# The service account itself must already exist (1Password > Developer > Service Accounts).

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

ITEM_TITLE="1Password Service Account Token"
VAULT="Employee"

if op item get "$ITEM_TITLE" --vault "$VAULT" >/dev/null 2>&1; then
  echo "Item '$ITEM_TITLE' already exists in vault '$VAULT'. Nothing to do."
  echo "Delete it first to re-store: op item delete '$ITEM_TITLE' --vault '$VAULT'"
  exit 0
fi

echo "Paste the service account token (input hidden, validated, then stored in 1Password):"
read -rs TOKEN
echo

if [[ -z "$TOKEN" ]]; then
  echo "No token entered. Aborting." >&2
  exit 1
fi

if [[ "$TOKEN" != ops_* ]]; then
  echo "warning: token does not start with 'ops_' — service account tokens normally do." >&2
fi

# Validate against 1Password before storing.
export OP_SERVICE_ACCOUNT_TOKEN="$TOKEN"
if ! op service-account ratelimit >/dev/null 2>&1; then
  unset OP_SERVICE_ACCOUNT_TOKEN
  echo "error: token failed validation (op service-account ratelimit). Not storing." >&2
  exit 1
fi
unset OP_SERVICE_ACCOUNT_TOKEN

# Build the item JSON via jq and pipe it in so the token never appears in
# command arguments (which land in process lists and shell history).
op item template get "API Credential" \
  | jq --arg title "$ITEM_TITLE" \
       --arg token "$TOKEN" \
       --arg note "Service account token for this machine. Created $(date +%Y-%m-%d). Manage at: 1Password > Developer > Service Accounts" \
       '.title = $title
        | .fields |= map(
            if .id == "credential" then .value = $token
            elif .id == "notesPlain" then .value = $note
            else . end)' \
  | op item create --vault "$VAULT" - >/dev/null

echo "Token stored in '$VAULT' as '$ITEM_TITLE' and validated."
echo "Load it in a shell with: opsa"
