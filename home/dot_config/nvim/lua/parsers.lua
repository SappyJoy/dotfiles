-- Treesitter parsers: the ones this config wants (a base set, plus each language's in
-- lang/) and an install of the missing ones. tree-sitter-cli builds them; where it
-- doesn't run (upstream's binary needs glibc 2.39: Ubuntu 24.04 and newer), nothing
-- is installed and those languages keep vim's syntax highlighting.
-- Used at start (plugins/treesitter.lua, after the first screen) and by the
-- installer (install.lua).
local M = {}

M.base = {
  'bash',
  'diff',
  'git_config',
  'git_rebase',
  'gitcommit',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'regex',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

function M.missing()
  local have = require('nvim-treesitter').get_installed()
  return vim.tbl_filter(function(p)
    return not vim.tbl_contains(have, p)
  end, vim.list_extend(vim.deepcopy(M.base), require('lang').list 'parsers'))
end

-- the install's task (nvim-treesitter's: :wait() blocks), or nil and why not
function M.install()
  local missing = M.missing()
  if #missing == 0 then
    return nil, 'all installed'
  end
  local ok, cli = pcall(vim.system, { 'tree-sitter', '--version' })
  if not ok or cli:wait().code ~= 0 then
    return nil, 'tree-sitter-cli is missing or does not run here'
  end
  return require('nvim-treesitter').install(missing)
end

return M
