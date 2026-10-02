-- SQL: the dadbod UI (<leader>db) with its completion; sql-formatter where the
-- project has its config. Saved queries live in the config's db_ui/ (tracked; the
-- connections, with their passwords, aren't).
return {
  parsers = { 'sql' },
  formatters = { sql = { 'sql_formatter' } },
  formats_if = { '.sql-formatter.json' },
  tools = { { 'sql-formatter', need = 'npm' } },
  plugins = {
    {
      'kristijanhusak/vim-dadbod-ui',
      dependencies = {
        { 'tpope/vim-dadbod', lazy = true },
        { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
      },
      cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
      keys = { { '<leader>db', '<cmd>DBUIToggle<cr>', desc = 'Databases (dadbod)' } },
      init = function()
        vim.g.db_ui_use_nerd_fonts = 1
        vim.g.db_ui_save_location = vim.fn.stdpath 'config' .. '/db_ui'
      end,
    },
    {
      'saghen/blink.cmp',
      opts = {
        sources = {
          per_filetype = { sql = { inherit_defaults = true, 'dadbod' } },
          providers = { dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' } },
        },
      },
    },
  },
}
