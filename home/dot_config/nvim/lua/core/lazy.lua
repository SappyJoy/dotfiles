-- lazy.nvim, cloned at its commit in lazy-lock.json (lazy writes the lock after
-- installing the other plugins, and would record whatever was cloned here).
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system { 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', lazypath }
  local ok, lock = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath 'config' .. '/lazy-lock.json'), '\n'))
  end)
  if ok and lock['lazy.nvim'] then
    vim.fn.system { 'git', '-C', lazypath, 'checkout', '--quiet', lock['lazy.nvim'].commit }
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({ { import = 'plugins' } }, {
  install = { colorscheme = { 'ayu-light' } },
  -- No luarocks: without it on a machine, lazy would build Lua 5.1 at every start.
  rocks = { enabled = false },
  change_detection = { enabled = false },
  performance = {
    rtp = {
      -- netrw: oil browses dirs; 0.12 needs it neither for gx nor for spell files
      disabled_plugins = { 'netrwPlugin', 'tohtml', 'tutor' },
    },
  },
})
