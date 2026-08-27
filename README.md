# dotfiles

Some scripts and [notes](NOTES.md) to setup and customize my working environment (Elementary OS).

This is opinionated and a constant WIP, but feel to look around anyway...

## Usage

    # set up dotfiles folder
    git clone https://github.com/firemound/dotfiles.git ~/.dotfiles

    # use install & config scripts
    cd ./dotfiles/scripts && ls -l

    # set up git workspace
    cd ~/src && gws update

Note to self: Using the https URL is easier on a new machine as no
SSH keys are needed. To work on the repo later on, change the remote
URL to ssh:

    git remote set-url origin git@github.com:firemound/dotfiles.git

## Package manager layering

This machine uses three package managers with deliberately separated responsibilities: apt (system foundation), nix (dev tooling), and mise (runtimes & agent harnesses). The ownership matrix, PATH precedence rules, and migration plan are documented in [`docs/package-manager-layering.md`](docs/package-manager-layering.md).

## Desktop customizations

The current Ubuntu/GDM + i3 desktop setup is documented in [`docs/i3-desktop-customizations.md`](docs/i3-desktop-customizations.md). It captures i3, Polybar, Rofi, Flameshot, autorandr, GTK dark-mode fallbacks, qutebrowser/1Password integration, and the active wallpaper.

## Recources

A brief list of helpful tools and resources:

- [mathiasbynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- [anishathalye's dotfiles](https://github.com/anishathalye/dotfiles)
- [dotbot](https://github.com/anishathalye/dotbot)
- [mackup](https://github.com/lra/mackup)
- [gws](https://github.com/StreakyCobra/gws)
- [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh/)
- [powerlevel9k theme](https://github.com/bhilburn/powerlevel9k)
- [antigen](https://github.com/zsh-users/antigen.git)
- [tmuxinator](https://github.com/tmuxinator/tmuxinator)

Big thanks to all authors and contributors!

## License

The MIT License (MIT)
