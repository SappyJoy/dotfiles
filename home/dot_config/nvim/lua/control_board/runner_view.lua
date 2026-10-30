-- What each running milestone runner is doing, in a window you open and close: its
-- milestone, steps ticked, last action, minutes since it last acted, tokens, and the run's
-- stop. The text is runner_status.py's own (its `detail` lines); nothing here calls Claude.
-- Input: open(runners) with the runners of the board's data, or open() to ask for them.
-- <leader>aS opens it; Enter on a runner of the board opens that runner; r refreshes, q closes.
local data = require 'control_board.data'

local M = {}

local ns = vim.api.nvim_create_namespace 'control_board_runners'
local HOT = { stalled = 'ControlBoardHot', waiting = 'ControlBoardDim', working = 'ControlBoardWork' }

local function lines_of(runners, only, loading)
  local lines, marks = { ' Runners' .. ((only or loading) and '' or ' (' .. #runners .. ')'), '' }, {}
  for _, r in ipairs(runners) do
    if not only or r.id == only then
      for i, text in ipairs(r.detail) do
        table.insert(lines, ' ' .. text)
        if i == 1 then
          table.insert(marks, { #lines, 'ControlBoardProject' })
        elseif text:match '^state' then
          table.insert(marks, { #lines, HOT[r.state] or 'Normal' })
        end
      end
      table.insert(lines, '')
    end
  end
  if #lines == 2 then
    table.insert(lines, loading and ' Reading the runners...' or ' No runner is working.')
    table.insert(lines, '')
  end
  table.insert(lines, ' r refresh  q or Esc close')
  table.insert(marks, { #lines, 'ControlBoardDim' })
  return lines, marks
end

local function window_of(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

local function draw(buf, runners, only, loading)
  local lines, marks = lines_of(runners, only, loading)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { end_col = #lines[1], hl_group = 'ControlBoardTitle' })
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, mark[1] - 1, 0, { end_col = #lines[mark[1]], hl_group = mark[2] })
  end
  local win = window_of(buf)
  if win then
    local width = 20
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line) + 1)
    end
    local height = math.min(#lines, vim.o.lines - 4)
    vim.api.nvim_win_set_config(win, {
      relative = 'editor',
      width = math.min(width, vim.o.columns - 4),
      height = height,
      row = math.floor((vim.o.lines - height) / 2) - 1,
      col = math.floor((vim.o.columns - math.min(width, vim.o.columns - 4)) / 2),
    })
  end
end

-- `only` is the id of one runner to show alone
function M.open(runners, only)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'controlboardrunners'
  vim.api.nvim_open_win(buf, true, { relative = 'editor', width = 40, height = 3, row = 1, col = 1, style = 'minimal', border = 'rounded' })
  vim.wo.cursorline = false
  local function close()
    local win = window_of(buf)
    if win then
      vim.api.nvim_win_close(win, true) -- deleting only the buffer would leave an empty float
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
  local function fill(list, loading)
    if vim.api.nvim_buf_is_valid(buf) then
      draw(buf, list, only, loading)
    end
  end
  vim.keymap.set('n', 'r', function()
    data.runners(function(list, err)
      if list then
        fill(list)
      else
        vim.notify(err, vim.log.levels.ERROR)
      end
    end)
  end, { buffer = buf, nowait = true, desc = 'Refresh the runners' })
  if runners then
    return fill(runners)
  end
  fill({}, true)
  data.runners(function(list, err)
    if list then
      fill(list)
    else
      close()
      vim.notify(err, vim.log.levels.ERROR)
    end
  end)
end

return M
