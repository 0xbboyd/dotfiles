-- Explicitly set mapleader to Space for Neovim compatibility
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Polyfill for Neovim 0.9 compatibility with modern plugins
if not vim.fs.joinpath then
  vim.fs.joinpath = function(...)
    return table.concat({ ... }, '/')
  end
end

-- 1. Source existing .vimrc to preserve all current hotkeys and settings
vim.cmd('source ~/.vimrc')

-- 2. Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3. Setup lazy.nvim and install plugins
require("lazy").setup({
  -- Tmux navigation (Fixes the <bs> mapping issue mentioned in .vimrc)
  { "christoomey/vim-tmux-navigator" },

  -- Modern syntax highlighting via Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "bash", "python", "html", "css", "markdown" },
        highlight = { enable = true },
      }
    end
  },

  -- Telescope for fuzzy finding (modern alternative to Ag/FZF)
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help Tags' })
    end
  },

  -- File tree (nvim-tree)
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    priority = 1000,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {
        view = {
          width = 30,
        },
      }
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle Explorer', silent = true, noremap = true })
    end,
  },

  -- Which-key for Spacemacs-like keybinding prompts
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
    }
  }
})
