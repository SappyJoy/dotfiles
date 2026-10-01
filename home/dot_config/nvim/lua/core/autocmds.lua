local group = vim.api.nvim_create_augroup('core', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight yanked text',
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Text soft-wraps at word boundaries and gets spelling only (no linters): misspellings
-- underlined, ]s/[s jump, z= suggests, zg adds.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Soft wrap and spell check in text',
  group = group,
  pattern = { 'markdown', 'text', 'gitcommit', 'tex', 'typst', 'org' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})
