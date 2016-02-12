# set locales
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# general settings
COMPLETION_WAITING_DOTS="true"

source $HOME/.dotfiles/external/antigen/antigen.zsh

# oh my zsh framework
antigen use oh-my-zsh

# OMZ powerlevel theme
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
antigen theme bhilburn/powerlevel9k powerlevel9k

antigen bundles <<EOBUNDLES
command-not-found
extract
git
heroku
ruby
rails
gem
bundler
node
npm
golang
vagrant
tmux
tmuxinator
colored-man-pages
zsh-users/zsh-completions src
zsh-users/zsh-history-substring-search
zsh-users/zsh-syntax-highlighting
rimraf/k
EOBUNDLES

# apply antigen config
antigen apply

source $HOME/.profile

# Disbale ZSH shared history
unsetopt share_history

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

