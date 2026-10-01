-- Languages are data: lua/lang/<name>.lua returns a table, and the capability
-- modules (treesitter, lsp, format, lint, mason, completion) read it from here.
-- A new language is one file. Fields, all optional:
--   parsers    = { 'python', ... }                 treesitter parsers
--   servers    = { name = { ...vim.lsp.config } }  LSP servers (nvim-lspconfig has defaults)
--   formatters = { filetype = { 'conform name' } }
--   formats_if = { 'ruff.toml', { 'pyproject.toml', '%[tool%.ruff' } }
--                a file (or a file holding a pattern) up the tree: the project
--                formats, so saving formats the changed lines (format.lua)
--   linters    = { filetype = { 'nvim-lint name' } }
--   tools      = { 'mason package', { 'package', need = 'npm' | 'python' | 'unzip' | 'go' | 'java' } }
--   filetypes  = { extension = { ets = 'typescript' } }   vim.filetype.add
--   plugins    = { lazy specs }                    language-only plugins
local M = {}

local cache
function M.all()
  if not cache then
    cache = {}
    local dir = vim.fn.stdpath 'config' .. '/lua/lang'
    for name, kind in vim.fs.dir(dir) do
      if kind == 'file' and name:match '%.lua$' and name ~= 'init.lua' then
        cache[name:sub(1, -5)] = require('lang.' .. name:sub(1, -5))
      end
    end
  end
  return cache
end

-- a list field of every language, concatenated
function M.list(field)
  local out = {}
  for _, lang in pairs(M.all()) do
    vim.list_extend(out, lang[field] or {})
  end
  return out
end

-- a map field of every language, merged
function M.map(field)
  local out = {}
  for _, lang in pairs(M.all()) do
    out = vim.tbl_extend('force', out, lang[field] or {})
  end
  return out
end

-- filetype -> formats_if markers of the language that formats it
function M.format_markers()
  local out = {}
  for _, lang in pairs(M.all()) do
    for ft in pairs(lang.formatters or {}) do
      out[ft] = lang.formats_if or {}
    end
  end
  return out
end

return M
