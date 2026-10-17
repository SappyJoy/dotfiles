-- The board's Week: runs milestone-flow's week.py (tokens, plan windows, finished
-- milestones, code growth over the last seven days), next to board.py, and keeps its
-- last answer. It reads a week of transcripts and git history, so it runs when the
-- board opens and on `r`, not on the board's five-second timer.
-- Output: week.py's JSON as a table (see plugins/milestone-flow/scripts/week.py).
local data = require 'control_board.data'

local M = {}

local last, err_text
local running = false
local callbacks = {}

function M.last()
  return last, err_text
end

-- done(week) when the new answer is in, or done(nil, reason)
function M.refresh(done)
  local board = data.script()
  local script = board and board:gsub('board%.py$', 'week.py')
  if not (script and vim.uv.fs_stat(script)) then
    err_text = 'week.py not found: run `make marketplace` in the toolkit'
    return done and done(nil, err_text)
  end
  table.insert(callbacks, done or false)
  if running then
    return
  end
  running = true
  local function finish(week, err)
    running = false
    last, err_text = week or last, err
    local waiting = callbacks
    callbacks = {}
    for _, fn in ipairs(waiting) do
      if fn then
        fn(week, err)
      end
    end
  end
  local started, err = pcall(vim.system, { 'python3', script, '--json' }, { text = true, timeout = 120000 }, function(out)
    vim.schedule(function()
      local ok, week = pcall(vim.json.decode, out.stdout or '', { luanil = { object = true, array = true } })
      if out.code ~= 0 or not ok then
        return finish(nil, vim.trim(out.stderr or '') ~= '' and out.stderr or 'week.py gave no data')
      end
      finish(week)
    end)
  end)
  if not started then
    finish(nil, tostring(err))
  end
end

return M
