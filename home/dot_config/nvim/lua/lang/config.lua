-- JSON, YAML, TOML: their servers with SchemaStore's schemas (pyproject, GitHub
-- Actions, docker compose, …: completion and checks for keys); taplo formats TOML
-- where the project has its config.
return {
  parsers = { 'json', 'yaml', 'toml' },
  servers = {
    jsonls = {
      before_init = function(_, config)
        config.settings = { json = { schemas = require('schemastore').json.schemas(), validate = { enable = true } } }
      end,
    },
    yamlls = {
      before_init = function(_, config)
        config.settings = { yaml = { schemaStore = { enable = false, url = '' }, schemas = require('schemastore').yaml.schemas() } }
      end,
    },
    taplo = {},
  },
  formatters = { toml = { 'taplo' } },
  formats_if = { 'taplo.toml', '.taplo.toml' },
  tools = { { 'json-lsp', need = 'npm' }, { 'yaml-language-server', need = 'npm' }, 'taplo' },
  plugins = { { 'b0o/SchemaStore.nvim', lazy = true } },
}
