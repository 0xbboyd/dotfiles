return {
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = "cd app && npm install 2>&1 >/dev/null",
    keys = {
      { "<leader>mP", "<cmd>MarkdownPreview<cr>", desc = "Markdown Preview (browser)" },
    },
    config = function()
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_browser = ""
    end,
  },

  -- Fallback: open rendered HTML directly for .md files with mermaid blocks
  {
    "delphinus/md-render.nvim",
    ft = "markdown",
    keys = {
      { "<leader>mp", "<Plug>(md-render-preview)",     desc = "Preview (inline)" },
      { "<leader>mt", "<Plug>(md-render-preview-tab)", desc = "Preview (tab)" },
    },
    config = function()
      if vim.env.TERM_PROGRAM == "tmux" and vim.env.WEZTERM_EXECUTABLE then
        vim.env.TERM_PROGRAM = "WezTerm"
      end
    end,
  },
}
