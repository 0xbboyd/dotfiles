return {
  {
    "tpope/vim-dadbod",
    cmd = { "DB" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Database UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod-ui"
      vim.g.db_ui_tmp_query_location = vim.fn.stdpath("data") .. "/dadbod-ui/tmp"
      vim.g.yendo_snowflake_db = "snowflake://brendan.boyd%40yendo.com@VRA15218/YENDO_DATA?warehouse=YENDO_DATA&rolename=PUBLIC&authenticator=externalbrowser"
      vim.g.dbs = {
        ["Yendo staging death-star"] = "postgres://teleport@127.0.0.1:15432/death-star-staging?sslmode=disable",
        ["Yendo Snowflake"] = vim.g.yendo_snowflake_db,
        ["Local DuckDB"] = "duckdb:" .. vim.fn.expand("~/.local/share/dadbod/local.duckdb"),
      }
      vim.api.nvim_create_user_command("SnowflakeSQL", function()
        vim.cmd("terminal snowsql -c yendo")
      end, { desc = "Open a persistent SnowSQL session for Yendo Snowflake" })
    end,
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
    dependencies = { "tpope/vim-dadbod" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          vim.bo.omnifunc = "vim_dadbod_completion#omni"
          vim.b.db = vim.b.db or vim.g.dbs["Yendo staging death-star"]
        end,
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          sql = { "snippets", "dadbod", "buffer" },
          mysql = { "snippets", "dadbod", "buffer" },
          plsql = { "snippets", "dadbod", "buffer" },
        },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}
