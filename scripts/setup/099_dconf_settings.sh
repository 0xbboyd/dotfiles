#! /bin/sh

echo "

DCONF SETTINGS
"

echo "- dim screen when idle"
gsettings set org.gnome.settings-daemon.plugins.power idle-dim true

echo "- mouse and touchpad"
gsettings set org.gnome.settings-daemon.peripherals.touchpad motion-threshold 3
gsettings set org.gnome.settings-daemon.peripherals.touchpad motion-acceleration 10.0
gsettings set org.gnome.settings-daemon.peripherals.touchpad disable-while-typing true
gsettings set org.gnome.settings-daemon.peripherals.touchpad tap-to-click true
gsettings set org.gnome.settings-daemon.peripherals.mouse motion-threshold 3
gsettings set org.gnome.settings-daemon.peripherals.mouse motion-acceleration 10

echo "- only use workspaces on primary screen"
gsettings set org.gnome.mutter workspaces-only-on-primary true

echo "- screenshot folder in dropbox"
SSDIR=~/Dropbox/Screenshots
gsettings set org.gnome.gnome-screenshot auto-save-directory "file://${SSDIR}"

echo "- set keyboard shortcuts"
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['<Primary><Super>space']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Primary>q']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Primary><Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Primary><Super>Down']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "<Super>h"

echo "- compose key"
gsettings set org.gnome.desktop.input-sources xkb-options "['compose:caps']"

echo "- gnome monospace font"
gsettings set  org.gnome.desktop.interface monospace-font-name "Hack"

echo "- desktop scaling to 2 (HiDPI)"
gsettings set org.gnome.desktop.interface scaling-factor 2

echo "- no dynamic workspaces"
gsettings set org.pantheon.desktop.gala.behavior dynamic-workspaces false

echo "- hot corners"
gsettings set org.pantheon.desktop.gala.behavior hotcorner-topright 'show-workspace-view'
gsettings set org.pantheon.desktop.gala.behavior hotcorner-topleft 'show-workspace-view'

echo "- don't show launcher button"
gsettings set org.pantheon.desktop.wingpanel show-launcher false

echo "- files settings"
gsettings set org.pantheon.files.preferences single-click false
gsettings set org.pantheon.files.preferences default-viewmode 'miller_columns'
gsettings set org.pantheon.files.column-view zoom-level 'small'
gsettings set org.pantheon.files.icon-view default-zoom-level 'small'
gsettings set org.pantheon.files.icon-view zoom-level 'small'

echo "- terminal settings"
gsettings set org.pantheon.terminal.settings cursor-color '#839496'
gsettings set org.pantheon.terminal.settings cursor-shape 'Underline'
gsettings set org.pantheon.terminal.settings foreground '#94a3a5'
gsettings set org.pantheon.terminal.settings font "Liberation Mono for Powerline"
gsettings set org.pantheon.terminal.settings palette '#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4'
gsettings set org.pantheon.terminal.settings background '#252e32'

echo "- scratch settings"
gsettings set org.pantheon.scratch.settings style-scheme 'solarized-dark'
gsettings set org.pantheon.scratch.settings auto-indent false
gsettings set org.pantheon.scratch.settings plugins-enabled "['folder-manager', 'highlight-word-selection', 'strip-trailing-save', 'filemanager', 'contractor', 'brackets-completion']"
gsettings set org.pantheon.scratch.settings use-system-font false
gsettings set org.pantheon.scratch.settings font "Hack"
gsettings set org.pantheon.scratch.settings show-right-margin true

echo "
done

"
