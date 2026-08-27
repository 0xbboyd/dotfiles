# Omarchy feature integration

Porting select features from `~/src/omarchy` (DHH's Hyprland/Arch distribution)
into this dotfiles repo for the Ubuntu + Wayland + nix + mise + Sway stack.

Omarchy is built for Hyprland + Arch/pacman. This plan extracts the layers that
are compositor- and distro-agnostic, adapting where needed. Anything that
requires `hyprctl`/`hyprpicker` or `pacman`/AUR is excluded or rewritten.

Source: `~/src/omarchy`
Target: `~/src/dotfiles`

## Scope decision

What we're NOT porting:
- The `omarchy` CLI router and `$OMARCHY_PATH` ecosystem (Arch-specific glue)
- pkg-* / install-* scripts (pacman/AUR)
- Hyprland config (hyprland.lua, bindings.lua — Hyprland's Lua DSL)
- Quickshell shell/bar (shell/ — Hyprland IPC)
- Plymouth, SDDM, limine, snapper, libalpm hooks (Arch/boot-specific)

What we ARE porting (in priority order):

## Phase 1: Copy-and-go configs (zero adaptation)

### 1.1 Fontconfig

- Source: `omarchy/default/fontconfig/conf.avail/50-omarchy.conf`
- Target: `config/fontconfig/conf.d/50-omarchy-fonts.conf`
- Dotbot: `~/.config/fontconfig/conf.d/50-omarchy-fonts.conf`
- Rationale: Maps sans-serif/serif/monospace to Liberation + JetBrainsMono Nerd
  Font, Arabic/Urdu Naskh vs Nastaliq handling, emoji fallback chains. Fixes
  real Chromium/Electron glyph rendering bugs. No platform dependency.
- Packages: `fonts-jetbrains-mono-nerd-font`, `fonts-noto-cjk`,
  `fonts-noto-color-emoji`, `fonts-liberation` (apt)

### 1.2 Git config additions

- Source: `omarchy/config/git/config`
- Target: Merge into existing `gitconfig`
- Rationale: rebase on pull, autoSetupRemote, histogram diff, colorMoved,
  mnemonicPrefix, branch sort by committerdate, tag sort by version, rerere.
  These are quality-of-life defaults most people forget to set.
- Changes: Append the missing `[diff]`, `[rerere]`, `[tag]`, `[column]`
  sections to the existing gitconfig. Don't touch existing `[alias]`,
  `[init]`, `[pull]`, `[push]` sections (already present).

### 1.3 Starship prompt

- Source: `omarchy/config/starship.toml`
- Target: `config/starship.toml`
- Dotbot: `~/.config/starship.toml`
- Rationale: Minimal, fast prompt (directory + git branch/status, cyan accent,
  repo-root highlighting). Compositor- and distro-agnostic.
- Packages: `starship` (nix)
- Shell hook: Add `eval "$(starship init zsh)"` to zshrc (after mise activate)

### 1.4 Tmux config upgrade

- Source: `omarchy/config/tmux/tmux.conf`
- Target: Merge improvements into existing `tmux.conf`
- Rationale: Omarchy's tmux config has better-organized bindings with named
  descriptions (`bind -N`), C-Space as secondary prefix, pane resize bindings,
  session navigation. The existing dotfiles tmux.conf is simpler.
- Changes: Adopt C-Space as secondary prefix (keep C-z as primary for muscle
  memory), add named-description bindings, add pane resize keys, add session
  navigation (P/N). Keep existing wl-clipboard integration and base-index 1.

### 1.5 btop config

- Source: `omarchy/config/btop/btop.conf`
- Target: `config/btop/btop.conf`
- Dotbot: `~/.config/btop/btop.conf`
- Rationale: truecolor, vim keys, rounded corners. Theme field will point to
  a static theme name (can't use Omarchy's dynamic theme staging path).
- Packages: `btop` (nix — already installed)

### 1.6 Terminal configs (ghostty, wezterm)

- Source: `omarchy/config/ghostty/config`
- Target: `config/ghostty/config`, `config/wezterm.lua`
- Dotbot: `~/.config/ghostty/config`, `~/.wezterm.lua`
- Rationale: Well-tuned terminal defaults with DejaVuSansM Nerd Font Mono,
  Shift+Enter as CSI-u for TUIs, copy/paste bindings. Theme colors are
  hardcoded to Tokyo Night instead of Omarchy's dynamic staging. Wezterm
  config upgraded from built-in color scheme to the same Tokyo Night palette
  with full ansi/brights, tab bar colors, and CSI-u keybinding for TUI parity.
- Packages: `ghostty` (nix or apt), `wezterm` (apt via pkg_wezterm.sh)
- Adaptation: Replace ghostty's `config-file = ?"..."` with inline colors.
  Wezterm's `config.color_scheme` replaced with an explicit `config.colors`
  table.

## Phase 2: Standalone scripts (trivial adaptation)

### 2.1 Notification helper

- Source: `omarchy/bin/omarchy-notification-send`
- Target: `scripts/commands/notify.sh`
- Dotbot: `~/.local/bin/notify`
- Rationale: Calls org.freedesktop.Notifications.Notify directly via gdbus
  instead of notify-send. Supports glyphs, urgency, images, action buttons,
  replace IDs. Better than raw notify-send. Compositor-agnostic.
- Adaptation: Rename to `notify`, remove `omarchy-notification-send` self-ref
  in usage text. No functional changes — it uses gdbus, not Hyprland.
- Packages: `glib` (apt — provides gdbus)

### 2.2 Reminder timer

- Source: `omarchy/bin/omarchy-reminder`
- Target: `scripts/commands/reminder.sh`
- Dotbot: `~/.local/bin/reminder`
- Rationale: Countdown timer reminders with desktop notifications. CLI:
  `reminder 5 "Tea ready"`, `reminder show`, `reminder clear`, `reminder -i`.
  Pure bash + notifications + date math. No Hyprland/Arch dependency.
- Adaptation: Rename internal references from `omarchy-notification-send` to
  `notify`. Otherwise unchanged.
- Sway keybindings: Add `Mod+Ctrl+R` for interactive reminder, etc.

### 2.3 Audio control scripts

- Source: `omarchy/bin/omarchy-audio-output-volume`, `-input-mute`,
  `-output-switch`, `-output-sink`, `-source-switch`, `-output-set-default`,
  `-input-set-default`, `-audio-tuning`, `-sink-availability`
- Target: `scripts/commands/audio/` directory
- Dotbot: `~/.local/bin/audio-volume`, `~/.local/bin/audio-mute`, etc.
- Rationale: wpctl/pactl-based audio control with DSP sink resolution, output
  switching, source switching. Works on any PipeWire/PulseAudio system.
- Adaptation: Strip `omarchy-osd` calls (Quickshell OSD — not available on
  Sway). The core wpctl/pactl logic is clean. Optionally emit notifications
  via `notify` instead of OSD.
- Packages: `pipewire`, `pipewire-pulse`, `wireplumber` (apt — already
  installed), `pavucontrol` (apt)
- Sway keybindings: Replace the raw wpctl commands in the current sway config
  with these wrapper scripts for better behavior (DSP resolution, OSD
  fallback via notify).

### 2.4 Brightness control

- Source: `omarchy/bin/omarchy-brightness-display`, `-brightness-keyboard`
- Target: `scripts/commands/brightness.sh`, `scripts/commands/kbd-brightness.sh`
- Dotbot: `~/.local/bin/brightness`, `~/.local/bin/kbd-brightness`
- Rationale: brightnessctl for backlight, ddcutil for external monitors.
  Percentage-based, focused-display aware. Works on Sway.
- Adaptation: Strip `omarchy-osd` calls and `hyprctl` monitor detection.
  Use swaymsg or /sys/class/backlight directly for focused display.
- Packages: `brightnessctl` (apt), `ddcutil` (apt, for external monitors)
- Sway keybindings: Wire to XF86MonBrightnessUp/Down keys.

### 2.5 Battery helpers

- Source: `omarchy/bin/omarchy-battery-status`, `-battery-present`, `-battery-low`
- Target: `scripts/commands/battery.sh`
- Dotbot: `~/.local/bin/battery`
- Rationale: Reads /sys/class/power_supply. Status, present check, low-battery
  threshold. Pure sysfs, no dependencies. Useful for swayidle low-battery
  suspend or waybar custom module.
- Adaptation: None needed for battery-status and battery-present.
  battery-low uses omarchy-notification-send — swap to `notify`.

## Phase 3: Capture scripts (moderate adaptation)

### 3.1 Screenshot

- Source: `omarchy/bin/omarchy-capture-screenshot`, `omarchy-capture-region`
- Target: `scripts/commands/screenshot.sh`
- Dotbot: `~/.local/bin/screenshot`
- Rationale: grim + slurp based screenshot with smart region/window/fullscreen
  modes, clipboard + file output, annotation editor hook.
- Adaptation: Remove hyprpicker screen-freeze overlay (Sway doesn't have it).
  Use slurp directly for region selection. Remove hyprctl hardware cursor
  workaround. Keep grim capture, wl-copy, file saving, editor hook (swappy).
- Packages: `grim`, `slurp`, `swappy`, `wl-clipboard` (nix — already installed)
- Sway keybindings: Replace existing `bindsym Print exec grim -g "$(slurp)"`
  with `screenshot smart` for better UX (clipboard + file, annotation).

### 3.2 OCR text extraction

- Source: `omarchy/bin/omarchy-capture-text`
- Target: `scripts/commands/ocr-screenshot.sh`
- Dotbot: `~/.local/bin/ocr-screenshot`
- Rationale: Select a screen region, run tesseract OCR, put text on clipboard.
  Genuinely useful for grabbing addresses/numbers from images.
- Adaptation: Remove hyprpicker freeze, use slurp directly. Otherwise
  unchanged — grim + tesseract + wl-copy is all standard.
- Packages: `tesseract-ocr`, `tesseract-ocr-eng` (apt)

### 3.3 QR code decode

- Source: `omarchy/bin/omarchy-capture-qr`
- Target: `scripts/commands/qr-screenshot.sh`
- Dotbot: `~/.local/bin/qr-screenshot`
- Rationale: Select a screen region, decode QR code, put result on clipboard.
  Useful for 2FA setup codes. Security-conscious: clipboard only, no stdout.
- Adaptation: Remove hyprpicker freeze, use slurp directly.
- Packages: `zbar-tools` (apt — provides zbarimg)

## Phase 4: Theme palette extraction

### 4.1 Color palettes

- Source: `omarchy/themes/*/colors.toml` (22 themes)
- Target: `config/omarchy-themes/` directory with colors.toml files
- Rationale: Curated color palettes (Tokyo Night, Catppuccin, Gruvbox, Rose
  Pine, Nord, Everforest, Kanagawa, etc.). Reusable as a data source for
  Sway border colors, waybar styling, terminal configs, and editor themes.
- No Dotbot link needed — these are data files, consumed by a theme script.

### 4.2 Theme switcher script

- Target: `scripts/commands/theme.sh`
- Dotbot: `~/.local/bin/theme`
- Function: Reads a colors.toml, generates Sway client colors, waybar CSS,
  terminal configs, and reloads the compositor/bar. Simplified version of
  Omarchy's template engine — enough to switch themes on Sway.
- This is the most ambitious item and may be deferred.

## Dotbot integration

Add to `.dotfiles.yml`:

```yaml
# Phase 1 links
"~/.config/fontconfig/conf.d/50-omarchy-fonts.conf": "config/fontconfig/conf.d/50-omarchy-fonts.conf"
"~/.config/starship.toml": "config/starship.toml"
"~/.config/btop/btop.conf": "config/btop/btop.conf"
"~/.config/foot/foot.ini": "config/foot/foot.ini"
"~/.config/ghostty/config": "config/ghostty/config"

# Phase 2-3 script links
"~/.local/bin/notify": "scripts/commands/notify.sh"
"~/.local/bin/reminder": "scripts/commands/reminder.sh"
"~/.local/bin/audio-volume": "scripts/commands/audio/volume.sh"
"~/.local/bin/audio-mute": "scripts/commands/audio/mute.sh"
"~/.local/bin/audio-output-switch": "scripts/commands/audio/output-switch.sh"
"~/.local/bin/brightness": "scripts/commands/brightness.sh"
"~/.local/bin/kbd-brightness": "scripts/commands/kbd-brightness.sh"
"~/.local/bin/battery": "scripts/commands/battery.sh"
"~/.local/bin/screenshot": "scripts/commands/screenshot.sh"
"~/.local/bin/ocr-screenshot": "scripts/commands/ocr-screenshot.sh"
"~/.local/bin/qr-screenshot": "scripts/commands/qr-screenshot.sh"
```

## Verification

After each phase:

```bash
# Phase 1
fc-match monospace  # should show JetBrainsMono Nerd Font
git config --get diff.algorithm  # histogram
starship --version
tmux source-file ~/.tmux.conf  # no errors
btop --version
foot --version  # if installed

# Phase 2-3
notify "test" "hello"
reminder 1 "test reminder"
audio-volume +1
brightness +5%
battery status
screenshot --help
```

## Commit strategy

One commit per phase, atomic changes. Follow the existing dotfiles commit
style (direct commits on master, per memory note).
