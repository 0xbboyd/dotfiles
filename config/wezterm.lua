local wezterm = require 'wezterm'
local config = {}

-- Use the config builder if available (modern version)
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Font — JetBrainsMono Nerd Font Mono (installed via raw TTFs in
-- ~/.local/share/fonts/nerd-fonts/; see docs/omarchy-integration.md)
config.font = wezterm.font 'JetBrainsMono Nerd Font Mono'
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

-- THEME-COLORS-BEGIN
config.colors = {
  foreground = '#fff5e1',
  background = '#1a0f0a',
  cursor_bg = '#fff5e1',
  cursor_fg = '#1a0f0a',
  cursor_border = '#fff5e1',
  selection_fg = '#fff5e1',
  selection_bg = '#2d1810',
  split = '#e87530',
  compose_cursor = '#f5a623',
  scrollbar_thumb = '#2d1810',
  tab_bar = {
    background = '#0d0704',
    active_tab = {
      bg_color = '#e87530',
      fg_color = '#1a0f0a',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#1a0f0a',
      fg_color = '#8b4513',
    },
    inactive_tab_hover = {
      bg_color = '#2d1810',
      fg_color = '#fff5e1',
    },
    new_tab = {
      bg_color = '#1a0f0a',
      fg_color = '#8b4513',
    },
    new_tab_hover = {
      bg_color = '#2d1810',
      fg_color = '#fff5e1',
    },
  },
  ansi = {
    '#1a0f0a', '#ef5350', '#4caf50', '#f5a623',
    '#5e81ac', '#ad8ee6', '#5e81ac', '#fff5e1',
  },
  brights = {
    '#a0522d', '#ef5350', '#4caf50', '#f5a623',
    '#5e81ac', '#ad8ee6', '#5e81ac', '#fff5e1',
  },
}
-- THEME-COLORS-END

-- Keybindings
config.keys = {
  -- Keep clipboard access in WezTerm's event loop. A synchronous wl-paste
  -- subprocess can wedge every window served by this GUI if its data source
  -- does not respond.
  { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
  -- Cmd/Ctrl + Shift + L to show the debug overlay
  { key = 'L', mods = 'CTRL|SHIFT', action = wezterm.action.ShowDebugOverlay },
}

-- Send Shift+Enter as CSI-u so TUIs (tmux, neovim) can distinguish it from Enter.
-- Matches the same binding in ghostty/config.
config.key_tables = {}
for _, mods in ipairs({ 'SHIFT', 'ALT|SHIFT' }) do
  table.insert(config.keys, {
    key = 'Enter',
    mods = mods,
    action = wezterm.action.SendString '\x1b[13;2u',
  })
end

return config
