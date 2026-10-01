-- Git in the buffer: gitsigns' hunks, and a review mode for changes made by an LLM
-- (or anyone): <leader>H keeps the hunk keys live until Esc.
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
}
