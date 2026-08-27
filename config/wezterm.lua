local wezterm = require 'wezterm'
local config = {}

-- Use the config builder if available (modern version)
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font — DejaVuSansM Nerd Font Mono (installed on this machine)
-- Has Nerd Font glyphs for powerline/waybar/tmux icons
config.font = wezterm.font 'DejaVuSansM Nerd Font Mono'
config.font_size = 11.0

-- Visual Appearance
config.window_background_opacity = 0.95
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Wayland: enable native Wayland for better scaling on HiDPI/Wayland
config.enable_wayland = true

-- Performance
config.scrollback_lines = 10000

-- Shell & Tmux optimization
-- Automatically launch tmux on startup (optional)
-- config.default_prog = { 'tmux' }

-- Tokyo Night color palette (same colors as foot/ghostty configs)
-- Source: ~/src/omarchy/themes/tokyo-night/colors.toml
config.colors = {
  foreground = '#a9b1d6',
  background = '#1a1b26',
  cursor_bg = '#c0caf5',
  cursor_fg = '#1a1b26',
  cursor_border = '#c0caf5',
  selection_fg = '#c0caf5',
  selection_bg = '#292e42',
  split = '#7aa2f7',
  compose_cursor = '#e0af68',
  scrollbar_thumb = '#24283b',
  tab_bar = {
    background = '#13141c',
    active_tab = {
      bg_color = '#7aa2f7',
      fg_color = '#1a1b26',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#1a1b26',
      fg_color = '#565f89',
    },
    inactive_tab_hover = {
      bg_color = '#24283b',
      fg_color = '#a9b1d6',
    },
    new_tab = {
      bg_color = '#1a1b26',
      fg_color = '#565f89',
    },
    new_tab_hover = {
      bg_color = '#24283b',
      fg_color = '#a9b1d6',
    },
  },
  ansi = {
    '#1a1b26', -- 0: black (background)
    '#f7768e', -- 1: red
    '#9ece6a', -- 2: green
    '#e0af68', -- 3: yellow
    '#7aa2f7', -- 4: blue
    '#ad8ee6', -- 5: magenta
    '#449dab', -- 6: cyan
    '#a9b1d6', -- 7: white (foreground)
  },
  brights = {
    '#414868', -- 8: bright black (muted)
    '#ff7a93', -- 9: bright red
    '#b9f27c', -- 10: bright green
    '#ff9e64', -- 11: bright yellow
    '#7da6ff', -- 12: bright blue
    '#bb9af7', -- 13: bright magenta
    '#0db9d7', -- 14: bright cyan
    '#c0caf5', -- 15: bright white (bright_foreground)
  },
}

-- Keybindings
config.keys = {
  -- Ctrl + V to paste from clipboard
  { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
  -- Cmd/Ctrl + Shift + L to show the debug overlay
  { key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ShowDebugOverlay },
}

-- Send Shift+Enter as CSI-u so TUIs (tmux, neovim) can distinguish it from Enter.
-- Matches the same binding in foot.ini and ghostty/config.
config.key_tables = {}
for _, mods in ipairs({ 'SHIFT', 'ALT|SHIFT' }) do
  table.insert(config.keys, {
    key = 'Enter',
    mods = mods,
    action = wezterm.action.SendString '\x1b[13;2u',
  })
end

return config
