-- The recording of a review's demo (milestone-flow, M20), played in a tab: `asciinema play`
-- in a terminal. A review in REVIEW.md may have .agent/review/M<n>/*.cast next to it; `p`
-- on the board and in the picker plays it. Space pauses it, Ctrl+C stops it, and
-- `Ctrl+\ Ctrl+N` then `q` closes the tab. A recording is as big as the terminal it was
-- made in (the review says which): in a smaller window it comes out garbled.
local M = {}

-- the project's .agent/review/M<n>/*.cast for a review row of the board
function M.recordings(row)
  local milestone = (row.title or ''):match '^M%d+'
  if not (milestone and row.project_path) then
    return {}
  end
  return vim.fn.glob(row.project_path .. '/.agent/review/' .. milestone .. '/*.cast', false, true)
end

local function winbar(name)
  return ' ▶ ' .. name:gsub('%%', '%%%%') .. '%=%#ControlBoardDim#Space pauses · Ctrl+C stops · Ctrl+\\ Ctrl+N then q closes '
end

function M.play(path)
  if vim.fn.executable 'asciinema' == 0 then
    return vim.notify('Playing a recording needs asciinema (a release binary in ~/.local/bin)', vim.log.levels.WARN)
  end
  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.jobstart({ 'asciinema', 'play', path }, { term = true })
  local name = vim.fs.basename(path)
  pcall(vim.api.nvim_buf_set_name, buf, 'recording ' .. name)
  vim.wo.winbar = winbar(name)
  vim.keymap.set('n', 'q', '<cmd>bwipeout!<cr>', { buffer = buf, desc = 'Close the recording' })
  -- closing the tab hides a terminal buffer and its job would go on: wipe it
  vim.api.nvim_create_autocmd('BufHidden', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end)
    end,
  })
  -- the last frame stays on the screen; Normal mode, where q closes it
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    once = true,
    callback = function()
      vim.cmd.stopinsert()
    end,
  })
  vim.cmd.startinsert()
end

-- p on a review row: its recording, or a choice between several
function M.play_review(row)
  if not (row and row.kind == 'review') then
    return vim.notify('Only a review has a recording', vim.log.levels.INFO)
  end
  local casts = M.recordings(row)
  if #casts == 0 then
    return vim.notify(row.title .. ' has no recording (.agent/review/' .. (row.title:match '^M%d+') .. '/*.cast)', vim.log.levels.INFO)
  end
  if #casts == 1 then
    return M.play(casts[1])
  end
  vim.ui.select(casts, {
    prompt = 'Recording',
    format_item = function(path)
      return vim.fs.basename(path)
    end,
  }, function(path)
    if path then
      M.play(path)
    end
  end)
end

return M
