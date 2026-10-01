local group = vim.api.nvim_create_augroup('core', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})
