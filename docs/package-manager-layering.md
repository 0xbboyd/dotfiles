# Package manager layering: apt + nix + mise

Three package managers, each owning a distinct layer. The boundaries are
deliberate — they prevent version conflicts and PATH confusion.

## Layer assignments

| Layer | Manager | Cadence | Purpose |
|-------|---------|---------|---------|
| 1 — System foundation | apt | Ubuntu release cycle | OS fundamentals, security patches, system services |
| 2 — Dev tooling | nix | Nixpkgs rolling | CLI tools that move faster than Debian stable but slower than runtimes |
| 3 — Runtimes & agent harnesses | mise | On demand, per-project | Language runtimes, agent CLIs, anything that needs per-project version pinning |

## Ownership matrix

Each package is owned by exactly one manager. No overlap.

### apt (system foundation)

These stay on apt because they need system-level integration (systemd,
kernel, display server, security) or because the Debian version is good
enough and moves slowly enough that a faster source isn't worth the
complexity.

- git
- zsh
- tmux / tmuxinator
- i3, polybar, rofi, sway, waybar, flameshot, autorandr, feh, picom
- podman, podman-compose (systemd socket activation, cgroup delegation)
- network-manager, OpenVPN, blueman
- gnupg, openssh-client
- jq, htop, tree, xclip, wl-clipboard
- python3-pip (system Python for OS tooling only)
- dconf-editor, papirus-icon-theme
- All libc, systemd, kernel, mesa, X/Wayland packages

Rule: if it needs a systemd unit, a kernel module, or deep display-server
integration, it stays on apt.

### nix (dev tooling)

These move to nix because Debian stable lags or because per-project
isolation is valuable. Nix provides newer versions without PPAs and
atomic rollbacks if an upgrade breaks something.

- neovim (currently via apt+unstable PPA — migrate to nix)
- eza (currently via apt — migrate to nix)
- git-delta (currently via apt — migrate to nix)
- ripgrep / fd / bat (currently via apt — migrate to nix)
- fzf
- lazygit
- starship / powerlevel10k (if ever needed via nix)
- Language servers: lua-language-server, gopls, pyright, typescript-language-server
- tree-sitter CLI
- yq (YAML processor)
- gh (GitHub CLI, if a newer version than apt is needed)

Rule: CLI dev tools and language servers go here. Nothing that requires
root or systemd.

### mise (runtimes & agent harnesses)

Already established. Manages anything with a version that varies per
project or needs to track upstream closely.

- node, python, go, java, bun
- aqua:anthropics/claude-code
- aqua:anomalyco/opencode
- aqua:openai/codex
- pipx:hermes-agent

Config lives at `~/.config/mise/mise.toml` (not tracked by dotfiles —
machine-local). Per-project overrides via `.mise.toml` or `.tool-versions`
in project roots.

Rule: if it's a language runtime or an agent CLI that ships frequent
releases, it goes here. Never install language runtimes via apt or nix.

## PATH precedence

Resolution order (first match wins):

```
mise shims  >  nix profile  >  apt (/usr/bin)
```

This means:
- mise always wins for runtimes — correct, because per-project pinning
  should override system defaults.
- nix wins over apt for dev tools — correct, because we want the nix
  version of neovim/eza/delta, not the apt version.
- apt is the fallback for everything else (system utilities).

### Shell init order

In `~/.zshrc` (and `~/.profile`), source in this order:

1. `.profile` — sets base PATH (`~/.local/bin`, go paths)
2. nix profile — sourced via `~/.nix-profile/etc/profile.d/nix.sh`
3. mise activate — `eval "$(mise activate zsh)"` (must come AFTER nix
   so mise shims take precedence)

The current `.zshrc` activates mise at line 77. When nix is installed,
add the nix profile source BEFORE the mise activation line:

```zsh
# nix — dev tooling layer (must be before mise so mise shims win)
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# mise — runtimes & agent harnesses (must be last activation so shims win)
eval "$(/home/bboyd/.local/bin/mise activate zsh)"
```

### Why this order works

mise creates shell shims that intercept commands. When you run `node`,
the mise shim resolves to the project-pinned version. When you run
`nvim`, there's no mise shim, so PATH falls through to the nix-managed
binary. When you run `apt`, there's no mise or nix intercept, so it
resolves to `/usr/bin/apt`.

## No-overlap rule

A package must live in exactly one manager. If you need to move something
between layers:

1. Remove it from the old manager (e.g., `sudo apt remove neovim`)
2. Install it in the new manager (e.g., `nix profile install nixpkgs#neovim`)
3. Verify `which neovim` points to the new source
4. Update this document

Never have the same package installed in two managers simultaneously.
If you do, PATH precedence determines which wins, but it's a debugging
trap — always remove from the old source first.

## Migration plan (apt -> nix)

Tools currently on apt that should migrate to nix:

| Package | Current source | Action |
|---------|---------------|--------|
| neovim | apt (unstable PPA) | `sudo apt remove neovim` then `nix profile install nixpkgs#neovim` |
| eza | apt | `sudo apt remove eza` then `nix profile install nixpkgs#eza` |
| git-delta | apt | `sudo apt remove git-delta` then `nix profile install nixpkgs#git-delta` |
| ripgrep | apt | `sudo apt remove ripgrep` then `nix profile install nixpkgs#ripgrep` |
| bat | apt (batcat) | `sudo apt remove bat` then `nix profile install nixpkgs#bat` |

After migration, also remove the neovim unstable PPA:

```bash
sudo add-apt-repository --remove ppa:neovim-ppa/unstable
```

And update `scripts/install/pkg_neovim.sh` to use nix instead of apt.

## Nix installation (on Ubuntu, not NixOS)

Multi-user installation (recommended for systemd integration):

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

After installation, restart the shell and verify:

```bash
nix --version
nix profile install nixpkgs#neovim
which nvim  # should show /nix/store/.../bin/nvim or ~/.nix-profile/bin/nvim
```

### Garbage collection

Nix keeps every generation. Set up a weekly GC to prevent disk bloat:

```bash
nix-collect-garbage --delete-older-than 30d
```

Or add a systemd timer / cron job for automatic cleanup.

## Verification

After setup, verify the layering is correct:

```bash
# mise layer — runtimes
which node    # mise shim
which python  # mise shim
which go      # mise shim

# nix layer — dev tooling
which nvim    # nix profile
which eza     # nix profile
which delta   # nix profile

# apt layer — system
which apt     # /usr/bin/apt
which podman  # /usr/bin/podman
which zsh     # /usr/bin/zsh
```

If any of these resolve to the wrong manager, check PATH order and
the no-overlap rule.
