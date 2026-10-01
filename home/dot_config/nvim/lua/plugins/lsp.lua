-- LSP: the servers of lang/ through nvim 0.11+'s vim.lsp.config/enable (defaults from
-- nvim-lspconfig), their binaries from mason. Keys on attach; 0.11's own gr* keys
-- stay (grn rename, gra action, grr references, gri implementation, grt type).

-- mason installs with npm, pip (a Python venv) or from zips; where one is missing
-- (no node; Ubuntu's python3 without python3-venv; no unzip), skip its tools
local python = vim.fn.resolve(vim.fn.exepath 'python3')
local has = {
  npm = vim.fn.executable 'npm' == 1,
  python = python ~= '' and vim.uv.fs_stat(vim.fs.dirname(vim.fs.dirname(python)) .. '/lib/' .. vim.fs.basename(python) .. '/ensurepip') ~= nil,
  unzip = vim.fn.executable 'unzip' == 1,
  go = vim.fn.executable 'go' == 1,
  java = vim.fn.executable 'java' == 1,
}

local function tools()
  local out = {}
  for _, tool in ipairs(require('lang').list 'tools') do
    if type(tool) == 'string' then
      table.insert(out, tool)
    elseif has[tool.need] then
      table.insert(out, tool[1])
    end
  end
  return out
end

local function telescope(picker)
  return function()
    require('telescope.builtin')[picker]()
  end
end

local function on_attach(args)
  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
  end
  map('gd', telescope 'lsp_definitions', 'Definition')
  map('gD', vim.lsp.buf.declaration, 'Declaration')
  map('grr', telescope 'lsp_references', 'References')
  map('gri', telescope 'lsp_implementations', 'Implementations')
  map('grt', telescope 'lsp_type_definitions', 'Type definition')
  map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('<leader>cr', vim.lsp.buf.rename, 'Rename')
  map('<leader>ss', telescope 'lsp_document_symbols', 'Symbols (file)')
  map('<leader>sS', telescope 'lsp_dynamic_workspace_symbols', 'Symbols (project)')
  map('<leader>ch', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = args.buf }, { bufnr = args.buf })
  end, 'Inlay hints on/off')
end

return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'mason-org/mason.nvim' },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', { callback = on_attach })
      for name, config in pairs(require('lang').map 'servers') do
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },
  {
    -- mason's bin dir goes first on PATH, so servers and formatters come from it
    'mason-org/mason.nvim',
    cmd = 'Mason',
    -- a fresh pip in each Python tool's venv: Ubuntu 20.04's pip 20.0 can't read
    -- today's wheel tags
    opts = { pip = { upgrade_pip = true } },
  },
  {
    -- installs the lang/ tools that are missing, once the UI is up; no version
    -- checks online (:MasonToolsUpdate does those)
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    event = 'VeryLazy',
    dependencies = { 'mason-org/mason.nvim' },
    cmd = { 'MasonToolsInstall', 'MasonToolsInstallSync', 'MasonToolsUpdate' },
    opts = function()
      return { ensure_installed = tools(), auto_update = false, run_on_start = true, start_delay = 2000 }
    end,
  },
}
