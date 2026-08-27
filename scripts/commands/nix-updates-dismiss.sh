#!/bin/bash
# nix-updates-dismiss: Right-click handler for the waybar nix-updates module.
# Uses the same hash computation as the checker so dismissals match.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix-updates"
mkdir -p "$STATE_DIR"

export NIX_REMOTE=daemon
export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"

locked_rev=$(nix profile list 2>/dev/null | grep "Locked flake URL" | head -1 | \
    sed -n 's|.*/nixpkgs-\([0-9]*pre[0-9]*\.\([a-f0-9]*\)\)/.*|\2|p' || true)

if [[ -z $locked_rev ]]; then
    exit 0
fi

latest_rev=$(nix flake metadata nixpkgs --json 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin).get('revision',''))" 2>/dev/null || true)

if [[ -z $latest_rev || "$locked_rev" == "$latest_rev" ]]; then
    exit 0
fi

raw=$(nix profile upgrade --dry-run --all 2>&1 || true)

hash_input=""

while IFS= read -r line; do
    if [[ $line == upgrading* ]]; then
        pkg=$(echo "$line" | sed -n "s|.*legacyPackages\.[^ ]*\.\([^']*\)'.*|\1|p")
        [[ -z $pkg ]] && continue
        hash_input+="${pkg} "
    fi
done <<< "$raw"

if [[ -z $hash_input ]]; then
    exit 0
fi

update_hash=$(echo -n "$hash_input" | md5sum | awk '{print $1}')
touch "$STATE_DIR/dismissed-$update_hash"

pkill -RTMIN+1 waybar 2>/dev/null || true
