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

  - `./scripts/remove_packages.sh`
  - `./scripts/dotfiles.sh`
  - `./scripts/install/base_packages.sh`
  - `chsh -s /bin/zsh`
  - `./scripts/install/pkg_powerline_fonts.sh`
  - `. ./.zshrc`
  - `./scripts/install/pkg_npm_packages.sh`
  - `./scripts/install/pkg_arc_theme.sh`
