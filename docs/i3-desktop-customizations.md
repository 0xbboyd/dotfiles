# i3 desktop customizations

This repo now captures the Ubuntu/GDM + i3 desktop setup built on 2026-06-02.

## Captured files

- `config/i3/config` — i3 session config, gaps, launchers, keybindings, Polybar, wallpaper, PolKit auth agent autostart.
- `config/polybar/` — Yendo Cowboy Powerline-style Polybar config and multi-monitor launch script.
- `config/rofi/config.rasi` — themed Rofi launcher config.
- `config/flameshot/flameshot.ini` — screenshot tool config.
- `screenlayout/auto.sh` — monitor layout auto-detection wrapper.
- `screenlayout/layout.sh` — docked HDMI-left/eDP-right fallback XRandR layout.
- `screenlayout/apply-desktop.sh` — applies display layout, wallpaper, and Polybar in dependency order to avoid startup races.
- `config/autorandr/` — saved `docked` and `mobile` monitor profiles.
- `config/gtk-3.0/settings.ini`, `config/gtk-4.0/settings.ini`, `gtkrc-2.0`, `config/environment.d/gtk-dark.conf` — GTK/libadwaita dark-mode fallbacks.
- `local/share/applications/org.gnome.Nautilus.desktop` — Nautilus override forcing dark mode and avoiding D-Bus activation ambiguity.
- `config/wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg` — active i3 wallpaper.
- `config/qutebrowser/config.py` and `local/share/qutebrowser/userscripts/qute-1password-okta` — qutebrowser keybinding for 1Password-backed Okta filling.

## Packages expected on Ubuntu 24.04

Install these before using the i3 session:

```bash
sudo apt-get install -y \
  i3 i3status i3lock suckless-tools rofi xss-lock feh picom \
  polybar fonts-powerline flameshot autorandr policykit-1-gnome \
  network-manager-gnome papirus-icon-theme
```

Optional but useful:

```bash
sudo apt-get install -y arandr pavucontrol blueman
```

## Important runtime behavior

### PolKit / 1Password system authentication

Bare i3 does not provide GNOME Shell's authentication prompt. The i3 config starts the standalone GNOME PolKit auth agent:

```text
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
```

The autostart is `exec_always` with an exact duplicate guard so i3 restarts repair a missing agent without creating duplicates.

Verify after login/restart:

```bash
pgrep -af '^/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1$'
```

### Display, wallpaper, and Polybar ordering

The i3 config intentionally runs one sequenced script instead of separate `exec_always` entries for XRandR, `feh`, and Polybar:

```text
~/.screenlayout/apply-desktop.sh
```

That script applies monitor layout first, waits briefly for XRandR clients to observe final geometry, then applies the wallpaper and launches one Polybar per monitor. The manual recovery binding is:

```text
Mod+Shift+x
```

### Wallpaper path

The dotfiles-managed i3 config uses:

```text
~/.config/wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg
```

The live machine previously used `~/Pictures/Wallpapers/pixel-frontier-sunset-stockcake-1680x1050-focal.jpg`; the dotfiles copy intentionally points at the managed wallpaper path.

### qutebrowser + 1Password

Keybinding:

```text
Ctrl-Alt-o
```

This runs `qute-1password-okta`, which reads:

```text
op://Employee/Okta/username
op://Employee/Okta/password
```

Safety properties:

- host allowlist: `login.yendo.com`, `yendo.okta.com`, `yendo-admin.okta.com`
- no clipboard writes
- no credential writes to disk

The 1Password CLI integration requires the 1Password desktop app and `op` CLI to be set up.

## Applying links

The `.dotfiles.yml` file links these paths with Dotbot. On an existing machine with real files already present, back them up first or move them aside before running the installer, because Dotbot will not overwrite arbitrary non-symlink files safely.

Minimum manual restore pattern for a fresh setup:

```bash
cd ~/src/dotfiles
./scripts/dotfiles.sh
```

Then log out from GNOME/GDM, choose the `i3` session from the gear menu, and log back in.

## Verification checklist

```bash
i3 -C -c ~/.config/i3/config
polybar --config=~/.config/polybar/config.ini --dump=height yendo
rofi -config ~/.config/rofi/config.rasi -dump-config >/tmp/rofi-config-dump.txt
flameshot --version
pgrep -af '^/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1$'
op read op://Employee/Okta/username >/dev/null && echo '1Password CLI ok'
```
