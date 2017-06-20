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
# Ubuntu make installation of Ubuntu Make binary symlink
PATH=/home/brendan/.local/share/umake/bin:$PATH

export GOPATH=$HOME/src/brig
export NS_EMAIL=bluebanyan@baywa-re.com
export NS_PASSWORD=Y29udDB1ci1NZW50YWwtZ2VuZXNpcwo=
