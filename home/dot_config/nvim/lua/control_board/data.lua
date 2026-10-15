-- The board's data: runs milestone-flow's board.py, keeps its last answer, and tells
-- whoever watches it (the board, the session tabs, the first page) when a new one is in.
-- Output: the collector's JSON as a table (see plugins/milestone-flow/scripts/board.py).
local M = {}

local INTERVAL_MS = 5000
local CLONE = vim.fn.expand '~/.local/share/claude-plugins/personal'
local SCRIPT = '/plugins/milestone-flow/scripts/board.py'

local last
local watchers = {}
local timer
local running = false
local callbacks = {} -- done functions of the run that is on
local path

-- Where board.py is: MILESTONE_FLOW_BOARD (tests), else the personal marketplace's
-- clone, which follows the toolkit's main; until a branch is merged there, the
-- checkout the clone was made from (its origin).
local function find_script()
  local found = vim.env.MILESTONE_FLOW_BOARD
  if found and vim.uv.fs_stat(found) then
    return found
  end
  if vim.uv.fs_stat(CLONE .. SCRIPT) then
    return CLONE .. SCRIPT
  end
  local origin = vim.fn.systemlist { 'git', '-C', CLONE, 'remote', 'get-url', 'origin' }
  if vim.v.shell_error == 0 and origin[1] and vim.uv.fs_stat(origin[1] .. SCRIPT) then
    return origin[1] .. SCRIPT
  end
end

function M.script()
  path = path or find_script()
  return path
end

function M.last()
  return last
end

-- Runs the collector; done(data) is called with the new data, or with nil and the
-- reason. A call during a run waits for that run.
function M.refresh(done)
  local script = M.script()
  if not script then
    return done and done(nil, "milestone-flow's board.py not found: run `make marketplace` in the toolkit")
  end
  table.insert(callbacks, done)
  if running then
    return
  end
  running = true
  local started, err = pcall(vim.system, { 'python3', script, '--json' }, { text = true, timeout = 20000 }, function(out)
    vim.schedule(function()
      running = false
      local waiting = callbacks
      callbacks = {}
      local ok, data = pcall(vim.json.decode, out.stdout or '', { luanil = { object = true, array = true } })
      if out.code ~= 0 or not ok then
        for _, fn in ipairs(waiting) do
          fn(nil, vim.trim(out.stderr or '') ~= '' and out.stderr or 'board.py gave no data')
        end
        return
      end
      last = data
      for _, fn in pairs(watchers) do
        fn(data)
      end
      for _, fn in ipairs(waiting) do
        fn(data)
      end
    end)
  end)
  if not started then -- python3 is missing: say so, and let the next refresh try again
    running = false
    local waiting = callbacks
    callbacks = {}
    for _, fn in ipairs(waiting) do
      fn(nil, tostring(err))
    end
  end
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

-- fn(data) runs after each refresh, which happens every few seconds while anyone
-- watches. Returns a function that stops watching.
function M.watch(fn)
  local handle = {}
  watchers[handle] = fn
  if not timer then
    timer = vim.uv.new_timer()
    timer:start(INTERVAL_MS, INTERVAL_MS, function()
      vim.schedule(M.refresh)
    end)
  end
  return function()
    watchers[handle] = nil
    if next(watchers) == nil then
      stop_timer()
    end
  end
end

return M
