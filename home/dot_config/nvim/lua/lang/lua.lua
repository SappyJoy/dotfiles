-- Lua: lua_ls, stylua, and lazydev (nvim's API and the plugins, for this config).
return {
  parsers = { 'lua', 'luadoc' },
  servers = {
    lua_ls = {
      settings = { Lua = { completion = { callSnippet = 'Replace' }, diagnostics = { disable = { 'missing-fields' } } } },
    },
  },
  formatters = { lua = { 'stylua' } },
  formats_if = { 'stylua.toml', '.stylua.toml' },
  tools = { 'lua-language-server', 'stylua' },
  plugins = {
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = { library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } } },
    },
    {
      'saghen/blink.cmp',
      opts = {
        sources = {
          per_filetype = { lua = { inherit_defaults = true, 'lazydev' } },
          providers = { lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 } },
        },
      },
    },
  },
}
