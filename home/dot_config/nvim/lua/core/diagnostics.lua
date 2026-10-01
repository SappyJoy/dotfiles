-- Diagnostics (LSP, linters): underline and sign everywhere, the message only on the
-- cursor's line. <leader>cD shows it on every line (and back).
local text = { current_line = true, spacing = 4, source = 'if_many', prefix = '●' }

vim.diagnostic.config {
  severity_sort = true,
  virtual_text = text,
  float = { source = 'if_many' },
}

vim.keymap.set('n', '<leader>cD', function()
  text.current_line = not text.current_line
  vim.diagnostic.config { virtual_text = text }
end, { desc = 'Diagnostics text: every line / cursor line' })
