-- Linters that aren't language servers (lang/ linters), after reading and saving.
-- Only the ones this machine has: mason skips some where npm or a venv is missing.
return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPost', 'BufWritePost' },
  config = function()
    local lint = require 'lint'
    lint.linters_by_ft = require('lang').map 'linters'
    local function run()
      local names = vim.tbl_filter(function(name)
        local linter = lint.linters[name]
        linter = type(linter) == 'function' and linter() or linter
        return vim.fn.executable(linter.cmd) == 1
      end, lint.linters_by_ft[vim.bo.filetype] or {})
      lint.try_lint(names)
    end
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
      group = vim.api.nvim_create_augroup('lint', { clear = true }),
      callback = run,
    })
    run() -- the buffer whose reading loaded this
  end,
}
