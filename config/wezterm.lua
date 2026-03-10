local wezterm = require 'wezterm'
local config = {}

-- Use the config builder if available (modern version)
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font settings
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 11.0

-- Visual Appearance
config.color_scheme = 'OneDark (base16)'
config.window_background_opacity = 0.95
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Wayland: disable native Wayland to avoid buffer scale mismatch on HiDPI
config.enable_wayland = false

-- Performance
config.scrollback_lines = 10000

-- Shell & Tmux optimization
-- Automatically launch tmux on startup (optional)
-- config.default_prog = { 'tmux' }

-- Keybindings
config.keys = {
  -- Ctrl + V to paste from clipboard
  { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
  -- Cmd/Ctrl + Shift + L to show the debug overlay
  { key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ShowDebugOverlay },
}

return config
