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
          lint.try_lint()
          -- Also try to lint with codespell if it's not explicitly mapped to the filetype
          -- but we generally want to check for typos
          -- lint.try_lint('codespell') 
        end,
      })
    end,
  },
}
