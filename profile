path+=$HOME/bin
path+=$HOME/.local/bin
path+=$PATH

source $HOME/.aliases

export EDITOR='vim'
# http://linux-sxs.org/housekeeping/lscolors.html
export LS_COLORS='di=1:fi=0:ln=35:pi=5:so=5:bd=5:cd=5:or=35:mi=35:ex=32'
export VAGRANT_DEFAULT_PROVIDER="libvirt"
export VAGRANT_HOME=$HOME/.vagrant.d
export CHE_DATA_FOLDER=~/workspace/che

# PATH="$HOME/bin:$HOME/.local/bin:$PATH"
