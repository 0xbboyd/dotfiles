#!/bin/bash
# nix-updates-check: Poll nixpkgs for available updates to nix profile packages.
# Emits waybar JSON matching the mise-updates module pattern.
#
# Compares the locked nixpkgs revision in the profile against the latest
# nixpkgs-unstable. If they differ, runs `nix profile upgrade --dry-run --all`
# to count how many packages would change.
#
# Output: waybar custom module JSON
# State: ~/.local/state/nix-updates/dismissed-<hash>

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix-updates"
mkdir -p "$STATE_DIR"

export NIX_REMOTE=daemon
export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"

# Get the locked nixpkgs revision from the first package in the profile
locked_rev=$(nix profile list 2>/dev/null | grep "Locked flake URL" | head -1 | \
    sed -n 's|.*/nixpkgs-\([0-9]*pre[0-9]*\.\([a-f0-9]*\)\)/.*|\2|p' || true)

if [[ -z $locked_rev ]]; then
    printf '{"text":"","class":"nix-updates-empty"}\n'
    exit 0
fi

# Fetch the latest nixpkgs-unstable revision
latest_rev=$(nix flake metadata nixpkgs --json 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin).get('revision',''))" 2>/dev/null || true)

if [[ -z $latest_rev || "$locked_rev" == "$latest_rev" ]]; then
    printf '{"text":"","class":"nix-updates-empty"}\n'
    exit 0
fi

# Revisions differ — there may be updates. Dry-run the upgrade to count changes.
# Parse dry-run output for package names that would change.
raw=$(nix profile upgrade --dry-run --all 2>&1 || true)

updates=()
hash_input=""

while IFS= read -r line; do
    # Dry-run output lines like: "upgrading 'legacyPackages.x86_64-linux.neovim' from ... to ..."
    if [[ $line == upgrading* ]]; then
        pkg=$(echo "$line" | sed -n "s|.*legacyPackages\.[^ ]*\.\([^']*\)'.*|\1|p")
        [[ -z $pkg ]] && continue
        # Extract version info if available
        updates+=("$pkg")
        hash_input+="${pkg} "
    fi
done <<< "$raw"

count=${#updates[@]}

if (( count == 0 )); then
    printf '{"text":"","class":"nix-updates-empty"}\n'
    exit 0
fi

update_hash=$(echo -n "$hash_input" | md5sum | awk '{print $1}')
dismiss_file="$STATE_DIR/dismissed-$update_hash"

if [[ -f $dismiss_file ]]; then
    printf '{"text":"","class":"nix-updates-dismissed"}\n'
    exit 0
fi

tooltip=$(printf '%s\n' "${updates[@]}")
tooltip_escaped=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read().strip())[1:-1])" <<< "$tooltip")

icon="\uf487"  # nix/snowflake-ish icon — using a package/wrench icon
if (( count == 1 )); then
    text=" ${icon} 1 nix update "
else
    text=" ${icon} ${count} nix updates "
fi

printf '{"text":"%s","tooltip":"%s","class":"nix-updates","percentage":%d}\n' \
    "$text" "$tooltip_escaped" "$count"
