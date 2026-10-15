-- Claude sessions inside nvim. A background session opens in a tab: a terminal running
-- `claude attach`, with a winbar that says what the session does. Closing the tab
-- detaches; the session goes on. A session started by hand in tmux is jumped to there.
-- In the tab, Claude scrolls with its own PageUp/PageDown (nvim's normal mode sees only
-- the screen), so in Normal mode Ctrl+U/Ctrl+D and the page keys send them.
local data = require 'control_board.data'

local M = {}

local STATE = { answer = 'needs you', working = 'working', idle = 'idle' }
local GROUP = { answer = 'ControlBoardAsk', working = 'ControlBoardWork', idle = 'ControlBoardDim' }
local KEYS = { page_up = '\27[5~', page_down = '\27[6~', bottom = '\27[1;5F' }

local unwatch

-- claude for the account whose config folder it is; the default folder (~/.claude)
-- is the account without CLAUDE_CONFIG_DIR
local function claude(config_dir, ...)
  local prefix = config_dir == vim.fn.expand '~/.claude' and { 'env', '-u', 'CLAUDE_CONFIG_DIR' } or { 'env', 'CLAUDE_CONFIG_DIR=' .. config_dir }
  return vim.list_extend(prefix, { 'claude', ... })
end

-- the account new sessions start in: the one nvim runs under, else the personal one
local function default_config()
  local env = vim.env.CLAUDE_CONFIG_DIR
  if env and env ~= '' then
    return env
  end
  local personal = vim.fn.expand '~/.claude-personal'
  return vim.uv.fs_stat(personal) and personal or vim.fn.expand '~/.claude'
end

local function find_tab(key)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.b[vim.api.nvim_win_get_buf(win)].control_session == key then
        return tab
      end
    end
  end
end

local function session_tabs()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    count = count + (vim.b[buf].control_session and 1 or 0)
  end
  return count
end

local function find_session(key)
  for _, s in ipairs(data.last() and data.last().sessions or {}) do
    if s.short == key then
      return s
    end
  end
end

-- The winbar of a session tab: project, name and what it does, with a hint on the right.
-- It is a plain string, set again whenever the board's data changes (a function in the
-- option, evaluated on every redraw, left the terminal's first screen unpainted).
local function winbar_text(buf)
  local label = vim.b[buf].control_label or ''
  local state = '%#ControlBoardDim#' .. (vim.b[buf].control_ended and 'ended' or 'attached')
  local s = find_session(vim.b[buf].control_session)
  if s then
    label = s.project .. ' · ' .. s.name
    state = '%#' .. GROUP[s.activity] .. '#' .. STATE[s.activity]
  end
  return ' ' .. label:gsub('%%', '%%%%') .. ' · ' .. state .. '%*%=%#ControlBoardDim#Ctrl+Z detaches · Ctrl+\\ Ctrl+N Normal mode '
end

local function update_winbars()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].control_session then
      vim.wo[win].winbar = winbar_text(buf)
    end
  end
end

local function send(buf, keys)
  vim.api.nvim_chan_send(vim.b[buf].terminal_job_id, keys)
end

local function map_keys(buf)
  local function map(lhs, keys, desc)
    vim.keymap.set('n', lhs, function()
      send(buf, keys)
    end, { buffer = buf, desc = desc })
  end
  map('<C-u>', KEYS.page_up, 'Scroll the session up')
  map('<PageUp>', KEYS.page_up, 'Scroll the session up')
  map('<C-d>', KEYS.page_down, 'Scroll the session down')
  map('<PageDown>', KEYS.page_down, 'Scroll the session down')
  map('G', KEYS.bottom, 'Scroll the session to the end')
  vim.keymap.set('n', 'q', '<cmd>bwipeout!<cr>', { buffer = buf, desc = 'Detach (the session goes on)' })
  -- vim-tmux-navigator maps <C-\> in Terminal mode, which breaks nvim's <C-\><C-n>
  vim.keymap.set('t', '<C-\\><C-n>', '<C-\\><C-n>', { buffer = buf, desc = 'Normal mode (the session goes on)' })
end

-- Open the session in a tab: its own, if it has one. s needs short, config_dir, and
-- project and name for the winbar until the board's data has the session.
function M.attach(s)
  local tab = find_tab(s.short)
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
    return vim.cmd.startinsert()
  end
  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].control_session = s.short
  vim.b[buf].control_label = (s.project or '') .. ' · ' .. (s.name or s.short)
  vim.fn.jobstart(claude(s.config_dir, 'attach', s.short), { term = true })
  pcall(vim.api.nvim_buf_set_name, buf, 'claude ' .. (s.project or '') .. ' ' .. s.short) -- the tab's label
  update_winbars()
  map_keys(buf)
  -- Ctrl+Z in Claude detaches: the client exits, and the tab goes with it
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    once = true,
    callback = function()
      vim.b[buf].control_ended = true
      update_winbars()
      if vim.v.event.status == 0 then
        vim.schedule(function()
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end)
      end
    end,
  })
  unwatch = unwatch or data.watch(update_winbars)
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      if session_tabs() <= 1 and unwatch then
        unwatch()
        unwatch = nil
      end
    end,
  })
  data.refresh()
  vim.cmd.startinsert()
end

-- a session started by hand in a tmux pane ("0:@3.%7"): go there
local function jump_tmux(where)
  local session, window, pane = where:match '^([^:]+):(@%d+)%.(%%%d+)$'
  if not (session and vim.env.TMUX) then
    return vim.notify('This session runs in tmux (' .. where .. '); open it there', vim.log.levels.WARN)
  end
  vim.system { 'tmux', 'switch-client', '-t', session, ';', 'select-window', '-t', window, ';', 'select-pane', '-t', pane }
end

-- s is a session of the board's data
function M.open(s)
  if s.kind == 'background' then
    M.attach(s)
  elseif s.tmux then
    jump_tmux(s.tmux)
  else
    vim.notify(s.name .. ' was started by hand outside tmux; only background sessions open here', vim.log.levels.WARN)
  end
end

-- Start a background session in a folder and open it
function M.start(root)
  local config = default_config()
  vim.notify('Starting a Claude session in ' .. vim.fs.basename(root) .. '…')
  vim.system(claude(config, '--bg'), { cwd = root, text = true }, function(out)
    vim.schedule(function()
      local short = (out.stdout or ''):match 'backgrounded · (%w+)'
      if not short then
        return vim.notify('claude --bg failed: ' .. vim.trim((out.stderr or '') .. (out.stdout or '')), vim.log.levels.ERROR)
      end
      M.attach { short = short, config_dir = config, project = vim.fs.basename(root), name = short }
    end)
  end)
end

return M
