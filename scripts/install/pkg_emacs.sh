#!/usr/bin/env sh

echo "installing spacemacs"
sudo git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

echo "installing source code pro fonts"
sudo git clone --depth 1 --branch release https://github.com/adobe-fonts/source-code-pro.git ~/.fonts/adobe-fonts/source-code-pro
sudo fc-cache -f -v ~/.fonts/adobe-fonts/source-code-pro

echo "installing emacs"
sudo add-apt-repository ppa:kelleyk/emacs
sudo apt-get update
sudo apt install emacs25

echo "installing material theme"
sudo git clone https://github.com/cpaulik/emacs-material-theme.git ~/.emacs.d/themes

echo "installing neo-tree icon fonts"
sudo git clone https://github.com/domtronn/all-the-icons.el.git ~/src/tools/all-the-icons
sudo ln -sf ~/src/tools/all-the-icons/fonts /usr/share/fonts/truetype/all-the-fonts
sudo fc-cache -f -v

echo "installing tern for js hints"
sudo node npm install -g tern

echo "now launching emacs for the first time for spacemacs package installation"
emacs --insecure
