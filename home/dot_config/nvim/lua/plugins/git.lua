-- Git in the buffer: gitsigns' hunks, and a review mode for changes made by an LLM
-- (or anyone): <leader>H keeps the hunk keys live until Esc. Whole changes and
-- history in diffview's tab (<leader>d…, Ctrl+Q closes it); lazygit in a float
-- (<leader>g, snacks).
local function gs(fn, ...)
  local args = { ... }
  return function()
    require('gitsigns')[fn](unpack(args))
  end
end

-- next/previous hunk, centered; in a diff window ]c/[c stay vim's own
local function hunk(dir)
  return function()
    if vim.wo.diff then
      vim.cmd.normal { dir == 'next' and ']c' or '[c', bang = true }
    else
      require('gitsigns').nav_hunk(dir, { target = 'all' }, function()
        vim.cmd 'normal! zz'
      end)
    end
  end
end

local function lines(fn)
  return function()
    require('gitsigns')[fn] { vim.fn.line '.', vim.fn.line 'v' }
  end
end

local function git(args)
  local out = vim.fn.systemlist(vim.list_extend({ 'git' }, args))
  return vim.v.shell_error == 0 and out[1] or nil
end

-- what this branch changed since it left main (or master)
local function branch_diff()
  for _, main in ipairs { 'main', 'master' } do
    if git { 'rev-parse', '--verify', '--quiet', main } then
      return vim.cmd('DiffviewOpen ' .. main .. '...HEAD')
    end
  end
  vim.notify('No main or master branch here', vim.log.levels.WARN)
end

-- the commit that last changed this line, against its parent
local function line_commit()
  local hash = git { 'blame', '-L', vim.fn.line '.' .. ',+1', '--porcelain', '--', vim.fn.expand '%:p' }
  hash = hash and hash:match '^%x+'
  if not hash or hash:match '^0+$' then
    return vim.notify('This line is not committed yet', vim.log.levels.WARN)
  end
  vim.cmd('DiffviewOpen ' .. hash .. '^!')
end

return {
  {
    'folke/which-key.nvim',
    opts = {
      spec = {
        { '<leader>h', group = 'hunks' },
        {
          '<leader>H',
          function()
            require('which-key').show { keys = '<leader>h', loop = true }
          end,
          desc = 'Review hunks (sticky)',
        },
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      { ']c', hunk 'next', desc = 'Next hunk' },
      { '[c', hunk 'prev', desc = 'Previous hunk' },
      { '<leader>h<Down>', hunk 'next', desc = 'Next hunk' },
      { '<leader>h<Up>', hunk 'prev', desc = 'Previous hunk' },
      { '<leader>hs', gs 'stage_hunk', desc = 'Stage hunk (again: unstage)' },
      { '<leader>hs', lines 'stage_hunk', mode = 'v', desc = 'Stage lines' },
      { '<leader>hr', gs 'reset_hunk', desc = 'Reset hunk' },
      { '<leader>hr', lines 'reset_hunk', mode = 'v', desc = 'Reset lines' },
      { '<leader>hS', gs 'stage_buffer', desc = 'Stage file' },
      { '<leader>hR', gs 'reset_buffer', desc = 'Reset file' },
      { '<leader>hu', gs 'undo_stage_hunk', desc = 'Undo last stage' },
      { '<leader>hp', gs 'preview_hunk_inline', desc = 'Preview hunk' },
      { '<leader>hb', gs('blame_line', { full = true }), desc = 'Blame line' },
      { '<leader>hd', gs 'diffthis', desc = 'Diff this file' },
      { 'ih', gs 'select_hunk', mode = { 'o', 'x' }, desc = 'Hunk' },
    },
  },
  {
    'folke/which-key.nvim',
    opts = { spec = { { '<leader>d', group = 'diff (diffview)' } } },
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>do', '<cmd>DiffviewOpen<cr>', desc = 'Changes (not committed)' },
      { '<leader>dm', branch_diff, desc = 'This branch against main' },
      { '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', desc = "This file's history" },
      { '<leader>dH', '<cmd>DiffviewFileHistory<cr>', desc = 'All history' },
      { '<leader>dl', '<cmd>.DiffviewFileHistory<cr>', desc = "This line's history" },
      { '<leader>dl', ':DiffviewFileHistory<cr>', mode = 'x', desc = "These lines' history" },
      { '<leader>dc', line_commit, desc = "This line's commit" },
    },
    opts = function()
      -- Ctrl+Q closes the whole diffview tab, as it quits elsewhere
      local close = { 'n', '<C-q>', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } }
      return {
        enhanced_diff_hl = true,
        keymaps = { view = { close }, file_panel = { close }, file_history_panel = { close } },
      }
    end,
  },
  {
    'folke/snacks.nvim',
    keys = {
      {
        '<leader>g',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
    },
  },
}
