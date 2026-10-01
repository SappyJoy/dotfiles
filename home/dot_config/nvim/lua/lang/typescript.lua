-- JavaScript, TypeScript and ArkTS (.ets, read as TypeScript): vtsls,
-- eslint where the project has its config, prettier where it has one.
local prettier = { 'prettierd', 'prettier', stop_after_first = true }

return {
  parsers = { 'javascript', 'typescript', 'tsx', 'jsdoc', 'json' },
  filetypes = { extension = { ets = 'typescript' } },
  servers = { vtsls = {}, eslint = {} },
  formatters = { javascript = prettier, typescript = prettier, javascriptreact = prettier, typescriptreact = prettier },
  formats_if = {
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.yaml',
    '.prettierrc.yml',
    '.prettierrc.js',
    '.prettierrc.cjs',
    '.prettierrc.mjs',
    'prettier.config.js',
    'prettier.config.cjs',
    'prettier.config.mjs',
    { 'package.json', '"prettier"' },
  },
  tools = { { 'vtsls', need = 'npm' }, { 'eslint-lsp', need = 'npm' }, { 'prettierd', need = 'npm' } },
}
