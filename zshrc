# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/home/bboyd/.zsh/completions" $fpath)
autoload -Uz compinit
compinit

# OPENSPEC:END

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# set locales
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# general settings
COMPLETION_WAITING_DOTS="true"

source $HOME/src/dotfiles/external/antigen/antigen.zsh

# oh my zsh framework
antigen use oh-my-zsh

# add support for 256 colors
export TERM="xterm-256color"

# OMZ powerlevel theme
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status dir vcs)
# antigen theme bhilburn/powerlevel9k powerlevel9k
antigen theme romkatv/powerlevel10k powerlevel10k

antigen bundles <<EOBUNDLES
autovenv
command-not-found
common-aliases
extract
git
git-flow
podman
kubectl
rsync
sudo
systemd
node
npm
golang
tmux
tmuxinator
colored-man-pages
EOBUNDLES

# apply antigen config
antigen apply

source $HOME/.profile

# colored man pages
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
export LESSHISTFILE=-

calc() {
  awk "BEGIN{ print $* }"
}

# nix — dev tooling layer (must be before mise so mise shims win)
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# mise — single version manager for runtimes and agent harnesses
eval "$(/home/bboyd/.local/bin/mise activate zsh)"

export NVM_DIR="/home/bboyd/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTFILE=~/.zsh_history
HIST_STAMPS=mm/dd/yyyy
HISTSIZE=5000
SAVEHIST=5000
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Go paths (also in .profile, but nvm resets PATH so re-add here)
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/go/bin:$PATH"

# opencode
export PATH=/home/bboyd/.opencode/bin:$PATH

# 1Password CLI — sign in at shell startup so op run never prompts mid-command
#if command -v op &>/dev/null; then
#    eval "$(op signin 2>/dev/null)" 2>/dev/null || true
#fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "/home/bboyd/.bun/_bun" ] && source "/home/bboyd/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$(npm prefix -g)/bin:$PATH"

# peon-ping quick controls
alias peon="bash /home/bboyd/.claude/hooks/peon-ping/peon.sh"
[ -f /home/bboyd/.claude/hooks/peon-ping/completions.bash ] && source /home/bboyd/.claude/hooks/peon-ping/completions.bash

# User-local binaries (also in .profile, re-added here after nvm resets PATH)
export PATH="$HOME/.local/bin:$PATH"

# i3 workspace rename helper.
# Usage: wsname code        -> renames current workspace to "<current-number>: code"
#        wsname "4: ops"   -> renames current workspace to "4: ops"
i3-workspace-name() {
  if [[ $# -eq 0 ]]; then
    echo 'Usage: wsname <workspace name>' >&2
    return 2
  fi

  local name="$*"
  local current_number
  current_number=$(i3-msg -t get_workspaces 2>/dev/null | python3 -c 'import json,sys; ws=json.load(sys.stdin); cur=next((w for w in ws if w.get("focused")), None); print(cur.get("num", "") if cur else "")' 2>/dev/null)

  if [[ -n "$current_number" && "$current_number" != "-1" && "$name" != <->:* ]]; then
    name="$current_number: $name"
  fi

  local quoted_name
  quoted_name=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$name") || return
  i3-msg "rename workspace to $quoted_name"
}
alias wsname='i3-workspace-name'

# X11 clipboard auth for tmux/terminal-launched tools.
# GNOME/Mutter stores the active Xwayland cookie under /run/user/<uid>/;
# tmux panes can lose XAUTHORITY, which makes xclip spam Neovim with
# "Authorization required". Repair it opportunistically for local shells.
if [[ -n "${DISPLAY:-}" && -z "${XAUTHORITY:-}" ]]; then
  _mutter_xauth=(/run/user/$UID/.mutter-Xwaylandauth.*(N.om[1]))
  if [[ -r "${_mutter_xauth[1]:-}" ]]; then
    export XAUTHORITY="${_mutter_xauth[1]}"
  fi
  unset _mutter_xauth
fi

# Hermes voice mode: user-local PortAudio fallback (sudo unavailable on this host)
export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBRARY_PATH="$HOME/.local/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"

# Machine-local shell config (secrets, internal infra, host-specific paths).
# Lives at ~/.zshrc.local — intentionally NOT tracked by the dotfiles repo.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Added by codebase-memory-mcp install
# ~/.local/bin already in PATH via .profile and above — removed duplicate

# mise — update all managed tools (runtimes + agent harnesses)
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'
