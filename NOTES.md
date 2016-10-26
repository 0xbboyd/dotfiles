# Notes

## OS Setup steps

### pre-format checklist

- Backup sensitive folders by running `./scripts/backup/create.sh`:
  - `~/.ssh`
  - `~/.gpg`
- Check git repos for uncommited stuff:
  - `~/src`
  - `~/.dotfiles`

### pre dotfiles

  - `/bin/sh ./backup_restore.sh` 
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
  - `./scripts/install/007_powerline_fonts.sh` 
  - `. ./.zshrc`
  - `./scripts/install/020_npm_packages.sh` 
  - `.scripts/install/031_tmuxinator.sh` 
  - `./scripts/install/120_arc_theme.sh` 