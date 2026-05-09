-- Yendo Cowboy colorscheme — custom standalone, no tokyonight dependency.
-- The actual highlight definitions live in colors/yendo-cowboy.lua (generated).
-- Regenerate with:  python3 config/yendo-cowboy/generate.py
-- Palette: config/yendo-cowboy/palette.yaml

return {
  -- Disable LazyVim's default tokyonight so it doesn't fight us
  { "folke/tokyonight.nvim", enabled = false },

  -- Tell LazyVim to use our custom colorscheme
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "yendo-cowboy" },
  },

  -- Lualine statusline — cowboy theme
  -- ── BEGIN_LUALINE ── (auto-generated)
        theme = {
normal = {
  a = { fg = "#1a0f0a", bg = "#e87530", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
insert = {
  a = { fg = "#1a0f0a", bg = "#4caf50", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
visual = {
  a = { fg = "#1a0f0a", bg = "#c4522a", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
replace = {
  a = { fg = "#1a0f0a", bg = "#ef5350", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
command = {
  a = { fg = "#1a0f0a", bg = "#f5a623", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
terminal = {
  a = { fg = "#1a0f0a", bg = "#8b4513", gui = "bold" },
  b = { fg = "#fff5e1", bg = "#2d1810" },
  c = { fg = "#a0522d", bg = "#1a0f0a" },
},
inactive = {
  a = { fg = "#8b4513", bg = "#1a0f0a", gui = "bold" },
  b = { fg = "#8b4513", bg = "#1a0f0a" },
  c = { fg = "#8b4513", bg = "#1a0f0a" },
},
        },
  -- ── END_LUALINE ──
}
