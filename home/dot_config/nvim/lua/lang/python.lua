-- Python: basedpyright (types, hover, completion, go to) and ruff (lint, fixes,
-- imports, format). A project's uv venv (.venv at its root) is found by itself.
local function venv_python(root)
  local python = root and root .. '/.venv/bin/python'
  return python and vim.uv.fs_stat(python) and python or nil
end

return {
  parsers = { 'python', 'toml' },
  servers = {
    basedpyright = {
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = 'standard',
            -- ruff reports these too (F821): one message, not two
            diagnosticSeverityOverrides = { reportUndefinedVariable = 'none' },
          },
        },
      },
      before_init = function(_, config)
        local python = venv_python(config.root_dir)
        if python then
          config.settings.python = vim.tbl_extend('force', config.settings.python or {}, { pythonPath = python })
        end
      end,
    },
    ruff = {
      on_attach = function(client)
        client.server_capabilities.hoverProvider = false -- basedpyright's is better
      end,
    },
  },
  formatters = { python = { 'ruff_format' } },
  formats_if = { 'ruff.toml', '.ruff.toml', { 'pyproject.toml', '%[tool%.ruff' }, { 'pyproject.toml', '%[tool%.black' } },
  tools = { { 'basedpyright', need = 'python' }, { 'ruff', need = 'python' }, { 'debugpy', need = 'python' } },
}
