return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        dockerfile = { 'hadolint' },
        json = { 'jsonlint' },
        -- Use codespell for all text/code files to catch typos
        -- You can extend this list
        text = { 'codespell' },
        javascript = { 'codespell' },
        typescript = { 'codespell' },
        python = { 'codespell' },
      }

      -- Create an autocommand to trigger linting
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only the linters this machine has: mason leaves some out where npm or
          -- Python's venv is missing (lsp.lua), and each would error on every buffer.
          local names = vim.tbl_filter(function(name)
            local linter = lint.linters[name]
            if type(linter) == 'function' then
              linter = linter()
            end
            return vim.fn.executable(linter.cmd) == 1
          end, lint.linters_by_ft[vim.bo.filetype] or {})
          lint.try_lint(names)
          -- Also try to lint with codespell if it's not explicitly mapped to the filetype
          -- but we generally want to check for typos
          -- lint.try_lint('codespell') 
        end,
      })
    end,
  },
}
