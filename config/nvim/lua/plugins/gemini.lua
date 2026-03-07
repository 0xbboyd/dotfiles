return {
  {
    "marcinjahn/gemini-cli.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_reload = true, -- Automatically reload buffers if the CLI modifies files
    },
    keys = {
      { "<leader>at", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini CLI" },
      { "<leader>af", "<cmd>Gemini add_file<cr>", desc = "Add File to Gemini" },
      { "<leader>ad", "<cmd>Gemini diagnostics<cr>", desc = "Send Diagnostics to Gemini" },
    },
  },
}
