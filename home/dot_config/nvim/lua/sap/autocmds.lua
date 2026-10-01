-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Text gets spelling only: misspellings underlined, ]s/[s jump, z= suggests, zg adds.
-- Russian where its spell file exists (0.11 can't download it with netrw off).
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Spell check English and Russian in text',
  group = vim.api.nvim_create_augroup('sap-text-spell', { clear = true }),
  pattern = { 'markdown', 'text', 'gitcommit', 'tex', 'org' },
  callback = function()
    local has_ru = #vim.api.nvim_get_runtime_file('spell/ru.utf-8.spl', false) > 0
    vim.opt_local.spell = true
    vim.opt_local.spelllang = has_ru and 'en,ru' or 'en'
    vim.opt_local.spellcapcheck = '' -- no "capital letter" marks, only misspellings
  end,
})
