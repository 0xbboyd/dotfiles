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
gh
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

# Disbale ZSH shared history
# unsetopt share_history

# colored man pages
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
export LESSHISTFILE=-
# man() {
#   LESS_TERMCAP_md=$'\e'"[1;36m" \
#   LESS_TERMCAP_me=$'\e'"[0m" \
#   LESS_TERMCAP_se=$'\e'"[0m" \
#   LESS_TERMCAP_so=$'\e'"[1;44;33m" \
#   LESS_TERMCAP_ue=$'\e'"[0m" \
#   LESS_TERMCAP_us=$'\e'"[1;32m" \
#   command man "$@"
# }

calc() {
  awk "BEGIN{ print $* }"
}

export NVM_DIR="/home/bboyd/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
export NODE_PATH=$NODE_PATH:/home/bboyd/.nvm/versions/node/v18.18.1/lib/node_modules

# if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
#    source /etc/profile.d/vte.sh
# fi

# if [ -d "/home/linuxbrew/.linuxbrew" ]; then
#    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTFILE=~/.zsh_history
HIST_STAMPS=mm/dd/yyyy
HISTSIZE=5000
SAVEHIST=5000
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/go/bin:$PATH"
export PATH="/home/bboyd/src/flutter/bin:$PATH"

# opencode
export PATH=/home/bboyd/.opencode/bin:$PATH

# Gemini commit message
function gcommit() {
  diff=$(git diff --staged)

  if [ -z "$diff" ]; then
    echo "No staged changes to commit."
    return 1
  fi
  echo "Generating commit message..."
  msg=$(echo "$diff" | gemini -p "Write a concise Conventional Commit message for this diff. Output ONLY the message.")
  git commit -m "$msg"
}

# 1Password CLI — sign in at shell startup so op run never prompts mid-command
if command -v op &>/dev/null; then
    eval "$(op signin 2>/dev/null)" 2>/dev/null || true
fi

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
