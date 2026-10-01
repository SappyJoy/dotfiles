-- Claude Code beside nvim in a tmux pane. claudecode.nvim (plugins/ai.lua) runs the
-- connection; this module is its terminal provider: it opens Claude in a tmux pane
-- or jumps to the one that's there.
-- Input: the account, a fish function (`claude` personal, `claude-team`).
-- Output: panes tagged with tmux's pane option @claude=<account>, which tells the
-- keys and the jump after a send which pane is whose.
local M = {}

M.account = 'claude' -- the account the last key opened; sends open this one

local function tmux(args)
  local out = vim.fn.systemlist(vim.list_extend({ 'tmux' }, args))
  return vim.v.shell_error == 0 and out or nil
end

-- The Claude panes in nvim's tmux session, nvim's own window first: the ones a key
-- opened (tagged) and the ones started by hand (running claude).
local function panes()
  local here = vim.env.TMUX_PANE
  local win = (tmux { 'display', '-p', '-t', here, '#{window_id}' } or {})[1]
  local found = {}
  local fmt = '#{pane_id} #{window_id} #{pane_current_command} #{@claude}'
  for _, line in ipairs(tmux { 'list-panes', '-s', '-t', here, '-F', fmt } or {}) do
    local id, window, cmd, account = line:match '^(%S+) (%S+) (%S+) ?(%S*)$'
    if id and id ~= here and (account ~= '' or cmd == 'claude') then
      table.insert(found, { id = id, account = account, here = window == win })
    end
  end
  table.sort(found, function(a, b)
    return a.here and not b.here
  end)
  return found
end

local function jump(id)
  tmux { 'select-window', '-t', id, ';', 'select-pane', '-t', id }
end

-- Opens the account's Claude to the right of nvim (in nvim's working directory,
-- connected to this nvim through env's port), or jumps to it if this window has it.
function M.open(account, env)
  if not vim.env.TMUX then
    return vim.notify('Claude opens in a tmux pane, and this nvim runs outside tmux', vim.log.levels.WARN)
  end
  account = account or M.account
  M.account = account
  for _, pane in ipairs(panes()) do
    if pane.here and pane.account == account then
      return jump(pane.id)
    end
  end
  local args = { 'split-window', '-h', '-P', '-F', '#{pane_id}', '-t', vim.env.TMUX_PANE, '-c', vim.fn.getcwd() }
  for name, value in pairs(env or {}) do
    vim.list_extend(args, { '-e', name .. '=' .. value })
  end
  vim.list_extend(args, { 'fish', '-c', account })
  local id = tmux(args)
  if id then
    tmux { 'set', '-p', '-t', id[1], '@claude', account }
  end
end

-- After a send: to the Claude it went to. The connection doesn't say which pane that
-- is, so the guess is the last key's account in nvim's window, then any Claude
-- there, then any in the session.
function M.focus()
  local found = panes()
  for _, pane in ipairs(found) do
    if pane.here and pane.account == M.account then
      return jump(pane.id)
    end
  end
  if found[1] then
    jump(found[1].id)
  end
end

-- The provider claudecode.nvim calls (:ClaudeCode, a send while no Claude is
-- connected). It hands over the command and the env with the port; the command is
-- the account's fish function instead, so the key's account wins.
M.provider = {
  setup = function() end,
  open = function(_, env)
    M.open(nil, env)
  end,
  simple_toggle = function(_, env)
    M.open(nil, env)
  end,
  focus_toggle = function(_, env)
    M.open(nil, env)
  end,
  close = function() end, -- a pane closes when its Claude exits
  ensure_visible = function() end, -- after a send: M.focus, on ClaudeCodeSendComplete
  get_active_bufnr = function() end,
  is_available = function()
    return true
  end,
}

return M
