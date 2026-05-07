-- Yendo Cowboy colorscheme — TokyoNight overridden with dusty sunset palette
-- Sourced from ~/.hermes/skins/yendo-agent.yaml
--
-- Palette reference:
--   #1a0f0a  deep mahogany   (bg)
--   #0d0704  darker earth    (bg_dark)
--   #2d1810  dark saddle     (bg_highlight, gutter)
--   #3d1e0f  mid leather     (bg visual, diff text)
--   #8b4513  saddle brown    (comments, muted, dim)
--   #a0522d  sienna          (fg_dark, borders, muted text)
--   #c4522a  rust red        (purple, blue1, red1, diff delete bg)
--   #e87530  sunset orange   (blue, orange, todo, border_highlight)
--   #f5a623  golden amber    (yellow, cyan, info, warning, git change)
--   #fff5e1  warm cream      (fg, primary text)
--   #4caf50  prairie green   (green, git add, hint, teal)
--   #ef5350  fire red        (red, error, git delete, magenta2)

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      on_colors = function(c)
        -- Backgrounds — deep earth tones
        c.bg = "#1a0f0a"
        c.bg_dark = "#0d0704"
        c.bg_dark1 = "#080302"
        c.bg_float = "#1a0f0a"
        c.bg_highlight = "#2d1810"
        c.bg_popup = "#1a0f0a"
        c.bg_search = "#3d1e0f"
        c.bg_sidebar = "#1a0f0a"
        c.bg_statusline = "#1a0f0a"
        c.bg_visual = "#2d1810"
        c.black = "#0d0704"

        -- Primary accent → sunset orange
        c.blue = "#e87530"
        c.blue0 = "#8b4513"
        c.blue1 = "#c4522a"
        c.blue2 = "#c4522a"
        c.blue5 = "#f5a623"
        c.blue6 = "#fff5e1"
        c.blue7 = "#3d1e0f"

        -- Borders — sienna/rust
        c.border = "#a0522d"
        c.border_highlight = "#e87530"

        -- Comments — saddle brown (warm, dim)
        c.comment = "#8b4513"

        -- Cyan → amber
        c.cyan = "#f5a623"

        -- Muted tones
        c.dark3 = "#a0522d"
        c.dark5 = "#8b4513"

        -- Diff backgrounds
        c.diff = {
          add = "#1a3d20",
          change = "#2d1810",
          delete = "#3d1515",
          text = "#3d1e0f",
        }

        -- Error — fire red
        c.error = "#ef5350"

        -- Foreground — warm cream
        c.fg = "#fff5e1"
        c.fg_dark = "#a0522d"
        c.fg_float = "#fff5e1"
        c.fg_gutter = "#2d1810"
        c.fg_sidebar = "#a0522d"

        -- Git colors
        c.git = {
          add = "#4caf50",
          change = "#f5a623",
          delete = "#ef5350",
          ignore = "#8b4513",
        }

        -- Green → prairie green
        c.green = "#4caf50"
        c.green1 = "#4caf50"
        c.green2 = "#3d8a40"

        -- Hint → prairie green
        c.hint = "#4caf50"

        -- Info → amber
        c.info = "#f5a623"

        -- Magenta → sienna (warm instead of garish purple)
        c.magenta = "#a0522d"
        c.magenta2 = "#ef5350"

        -- Orange → sunset orange
        c.orange = "#e87530"

        -- Purple → rust red
        c.purple = "#c4522a"

        -- Rainbow sequence
        c.rainbow = {
          "#e87530", "#f5a623", "#4caf50", "#c4522a",
          "#a0522d", "#fff5e1", "#8b4513", "#ef5350",
        }

        -- Red → fire red
        c.red = "#ef5350"
        c.red1 = "#c4522a"

        -- Teal → prairie green
        c.teal = "#4caf50"

        -- Terminal colors
        c.terminal = {
          black = "#0d0704",
          black_bright = "#2d1810",
          blue = "#e87530",
          blue_bright = "#f5a623",
          cyan = "#f5a623",
          cyan_bright = "#fff5e1",
          green = "#4caf50",
          green_bright = "#4caf50",
          magenta = "#a0522d",
          magenta_bright = "#c4522a",
          red = "#ef5350",
          red_bright = "#ef5350",
          white = "#a0522d",
          white_bright = "#fff5e1",
          yellow = "#f5a623",
          yellow_bright = "#f5a623",
        }

        c.terminal_black = "#2d1810"

        -- Todo → sunset orange
        c.todo = "#e87530"

        -- Warning → amber
        c.warning = "#f5a623"

        -- Keep NONE as NONE
        -- c.none is already "NONE"
      end,
    },
  },

  -- Set it as the colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- Lualine statusline — cowboy theme
  -- Must be explicit because theme="auto" reads raw tokyonight, bypassing on_colors
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
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
      },
    },
  },
}
