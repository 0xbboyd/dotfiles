# Notes

## OS Setup steps

### pre-format checklist

- Backup sensitive folders by running `./scripts/backup/create.sh`:
  - `~/.ssh`
  - `~/.gpg`
- Alternatively, if bup and bup aliases are setup:
  - bup-keys
- Check git repos for uncommited stuff:
  - `~/src`
  - `~/workspace`
  - `~/.dotfiles`

### pre dotfiles

  - `./scripts/backup/restore.sh`
  - `mv .backup-tmp/.ssh ~/`
  - `rm -rf ~/.gnupg/`
  - `mv .backup-tmp/.gnupg/ ~/`
  - `rm -rf .backup-tmp/`
  - `sudo apt-get install git`
  - `git clone https://github.com/firemound/dotfiles.git ~/.dotfiles`

### scripts

  - `cd ~/.dotfiles`
  - `./scripts/remove_packages.sh`
  - `./scripts/dotfiles.sh`
  - `./scripts/install/base_packages.sh`
  - `chsh -s /bin/zsh`
  - `./scripts/install/pkg_powerline_fonts.sh`
  - `. ./.zshrc`
  - `./scripts/install/pkg_npm_packages.sh`
  - `./scripts/install/pkg_arc_theme.sh`
  - Install the dropbox package, signin, and then install bups

### package managers

  After base packages, set up the three-layer package manager stack.
  See [docs/package-manager-layering.md](docs/package-manager-layering.md) for
  the full ownership matrix and PATH rules.

  - apt: already installed via base_packages.sh (system foundation)
  - nix: `sh <(curl -L https://nixos.org/nix/install) --daemon`
    - Migrate dev tools from apt: neovim, eza, git-delta, ripgrep, bat
    - Remove the neovim unstable PPA after migration
  - mise: `curl https://mise.run | sh`
    - Runtimes: node, python, go, java, bun
    - Agent harnesses: claude-code, opencode, codex, hermes-agent
    - Config at `~/.config/mise/mise.toml` (not tracked by dotfiles)
