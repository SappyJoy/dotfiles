-- Tells you, in nvim, when a Claude session needs an answer or goes idle and when a
-- review appears: a notification (snacks) with the project's name. <leader>an opens
-- what the newest one is about: the session in a tab, the review in REVIEW.md. The
-- facts are the board's data (data.lua); each answer is compared with the one before,
-- and what already waits when nvim starts is not announced. The desktop and tmux are
-- told by Claude's Notification hook (~/.claude/notify-hook.sh), the phone by Claude
-- Code's own push.
local data = require 'control_board.data'

local M = {}

local POLL_MS = 10000
local TOAST_MS = 10000
local DETAIL_WIDTH = 100
local KEEP = 20 -- notifications <leader>an can still open

local before -- the last answer in short: sessions by id -> what they do, reviews by key
local unread = {} -- the rows of the notifications not opened yet, newest last
local timer

local function review_key(row)
  return row.project_path .. '\0' .. row.title
end

local function snapshot(board)
  local now = { sessions = {}, reviews = {} }
  for _, s in ipairs(board.sessions or {}) do
    now.sessions[s.id] = s.activity
  end
  for _, row in ipairs(board.needs or {}) do
    if row.kind == 'review' and not row.put_off then
      now.reviews[review_key(row)] = true
    end
  end
  return now
end

local function shorten(text)
  text = vim.trim(text):gsub('%s+', ' ')
  return vim.fn.strchars(text) > DETAIL_WIDTH and vim.fn.strcharpart(text, 0, DETAIL_WIDTH - 1) .. '…' or text
end

-- What is new in the board's data since the snapshot `prev`: a session that now asks
-- for an answer, one that went from working to idle, a review that was not there (one
-- the user put off is no news). Each change: project, text, level, the row <leader>an
-- opens, and for a session its short id.
function M.changes(prev, board)
  local found = {}
  for _, s in ipairs(board.sessions or {}) do
    local was = prev.sessions[s.id]
    if s.activity == 'answer' and was ~= 'answer' then
      local detail = shorten(s.detail or '')
      table.insert(found, {
        project = s.project,
        text = s.name .. ' needs an answer' .. (detail ~= '' and ('\n' .. detail) or ''),
        level = vim.log.levels.WARN,
        row = { kind = 'answer', session = s.id },
        tab = s.short,
      })
    elseif s.activity == 'idle' and was == 'working' then
      table.insert(found, {
        project = s.project,
        text = s.name .. ' is idle',
        level = vim.log.levels.INFO,
        row = { kind = 'session', session = s.id },
        tab = s.short,
      })
    end
  end
  for _, row in ipairs(board.needs or {}) do
    if row.kind == 'review' and not row.put_off and not prev.reviews[review_key(row)] then
      table.insert(found, {
        project = row.project,
        text = row.title .. ' is ready for your review',
        level = vim.log.levels.WARN,
        row = row,
      })
    end
  end
  return found
end

local function announce(change)
  -- you are typing in that session's tab: no need to tell you
  if change.tab and vim.b[vim.api.nvim_get_current_buf()].control_session == change.tab then
    return
  end
  table.insert(unread, change.row)
  if #unread > KEEP then
    table.remove(unread, 1)
  end
  vim.notify(change.text .. '\n<leader>an opens it', change.level, { title = change.project, timeout = TOAST_MS })
end

local function on_data(board)
  local prev = before
  before = snapshot(board)
  if prev then
    for _, change in ipairs(M.changes(prev, board)) do
      announce(change)
    end
  end
end

-- <leader>an: the newest notification's session or review
function M.open_latest()
  local row = table.remove(unread)
  if not row then
    return vim.notify('No new Claude notification', vim.log.levels.INFO)
  end
  require('control_board').open_row(row)
end

-- Listens to every refresh of the board's data and asks for one every few seconds,
-- also when no board is open. Needs milestone-flow's board.py.
function M.start()
  if timer or not data.script() then
    return
  end
  data.listen(on_data)
  if data.last() then
    on_data(data.last())
  end
  timer = vim.uv.new_timer()
  timer:start(POLL_MS, POLL_MS, function()
    vim.schedule(data.refresh)
  end)
end

return M
