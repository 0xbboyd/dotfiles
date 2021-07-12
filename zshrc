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
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(status dir vcs)
antigen theme bhilburn/powerlevel9k powerlevel9k

antigen bundles <<EOBUNDLES
ansible
aws
command-not-found
common-aliases
extract
emacs
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
unsetopt share_history

# colored man pages
man() {
  LESS_TERMCAP_md=$'\e'"[1;36m" \
  LESS_TERMCAP_me=$'\e'"[0m" \
  LESS_TERMCAP_se=$'\e'"[0m" \
  LESS_TERMCAP_so=$'\e'"[1;44;33m" \
  LESS_TERMCAP_ue=$'\e'"[0m" \
  LESS_TERMCAP_us=$'\e'"[1;32m" \
  command man "$@"
}


calc() {
  awk "BEGIN{ print $* }"
}

export NVM_DIR="/home/bboyd/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
export NODE_PATH=$NODE_PATH:/home/bboyd/.nvm/versions/node/v10.14.2/lib/node_modules

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
   source /etc/profile.d/vte.sh
fi
