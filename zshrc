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

source $HOME/.dotfiles/external/antigen/antigen.zsh

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
ansible
aws
command-not-found
common-aliases
extract
dnf
git
git-flow
kubectl
rsync
sudo
systemd
terraform
node
npm
golang
vagrant
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

# export NVM_DIR="/home/bboyd/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# export NODE_PATH=$NODE_PATH:/home/bboyd/.nvm/versions/node/v10.14.2/lib/node_modules

# if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
#    source /etc/profile.d/vte.sh
# fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTFILE=~/.zsh_history
HIST_STAMPS=mm/dd/yyyy
HISTSIZE=5000
SAVEHIST=5000
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
