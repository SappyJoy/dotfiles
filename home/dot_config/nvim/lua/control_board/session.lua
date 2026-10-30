-- Claude sessions inside nvim. A background session opens in a tab: a terminal running
-- `claude attach`, with a winbar that says what the session does. Closing the tab
-- detaches; the session goes on. A session started by hand in tmux is jumped to there.
-- In the tab, Claude scrolls with its own PageUp/PageDown (nvim's normal mode sees only
-- the screen), so in Normal mode Ctrl+U/Ctrl+D and the page keys send them.
-- Space types a space at the prompt, so Alt+A stands for <leader>a there: Alt+A W picks,
-- Alt+A B goes to the board. Ctrl+6 switches between the board and the last session, Ctrl+Z
-- (claude attach's own detach) ends the client and lands on the board. The footer (the
-- statusline, ui/statusline.lua) lists the keys of the mode you are in.
local data = require 'control_board.data'

local M = {}

local STATE = { answer = 'needs you', working = 'working', idle = 'idle' }
local GROUP = { answer = 'ControlBoardAsk', working = 'ControlBoardWork', idle = 'ControlBoardDim' }
local KEYS = { page_up = '\27[5~', page_down = '\27[6~', bottom = '\27[1;5F' }

local unwatch

vim.keymap.set('n', '<Plug>(ControlBoardLeaderA)', function()
  require('which-key').show { keys = '<leader>a', mode = 'n' }
end, { desc = 'The <leader>a popup' })

-- claude for the account whose config folder it is; the default folder (~/.claude)
-- is the account without CLAUDE_CONFIG_DIR
local function claude(config_dir, ...)
  local prefix = config_dir == vim.fn.expand '~/.claude' and { 'env', '-u', 'CLAUDE_CONFIG_DIR' } or { 'env', 'CLAUDE_CONFIG_DIR=' .. config_dir }
  return vim.list_extend(prefix, { 'claude', ... })
end

-- the account new sessions start in: the one nvim runs under, else ~/.claude
local function default_config()
  local env = vim.env.CLAUDE_CONFIG_DIR
  if env and env ~= '' then
    return env
  end
  return vim.fn.expand '~/.claude'
end

-- the window of the session with this key, in any tab
local function find_win(key)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.b[vim.api.nvim_win_get_buf(win)].control_session == key then
      return win
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
  return ' ' .. label:gsub('%%', '%%%%') .. ' · ' .. state .. '%* '
end

local function update_winbars()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].control_session then
      local text = winbar_text(buf)
      if vim.wo[win].winbar ~= text then -- setting it again, even unchanged, closes the which-key popup
        vim.wo[win].winbar = text
      end
    end
  end
end

-- the keys that work in a session window, by mode (n: Normal, t: typing), for the footer
local FOOTER = {
  t = ' Alt+A menu · Alt+A Esc scroll · Ctrl+6 board · Ctrl+Z detach ',
  n = ' i type · Ctrl+U/Ctrl+D page · G end · Ctrl+6 board · Alt+A menu · ? keys ',
}

local last_key -- the session window we were in last: where Ctrl+6 on the board goes

-- the board's tab, in front
local function show_board()
  local board = require 'control_board'
  local win = board.board_win()
  if not win then
    return board.open()
  end
  vim.api.nvim_set_current_win(win)
end

-- Close a session window (the client exits, the session goes on) and land on the board
local function leave(buf)
  local here = false -- a session that ends behind your back leaves you where you are
  for _, w in ipairs(vim.fn.win_findbuf(buf)) do
    here = here or vim.tbl_contains(vim.api.nvim_tabpage_list_wins(0), w)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  if here and require('control_board').board_win() then
    show_board()
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
  vim.keymap.set('n', 'q', function()
    leave(buf)
  end, { buffer = buf, desc = 'Detach (the session goes on)' })
  vim.keymap.set('n', '?', function()
    require('control_board').cheatsheet()
  end, { buffer = buf, desc = 'The keys of the board and sessions' })
  vim.keymap.set({ 'n', 't' }, '<C-^>', show_board, { buffer = buf, desc = 'The board' })
  -- vim-tmux-navigator maps <C-\> in Terminal mode, which breaks nvim's <C-\><C-n>
  vim.keymap.set('t', '<C-\\><C-n>', '<C-\\><C-n>', { buffer = buf, desc = 'Normal mode (the session goes on)' })
  -- Alt+A: Normal mode, then the <leader>a popup, which waits for the key as long as it
  -- takes (the pending keys of a plain <leader>a would run as `a` after timeoutlen, 300 ms).
  -- Esc closes the popup and stays in Normal mode. Alt+Ф is the same in the Russian layout.
  for _, lhs in ipairs { '<M-a>', '<M-ф>' } do
    vim.keymap.set('t', lhs, '<C-\\><C-n><Plug>(ControlBoardLeaderA)', { buffer = buf, remap = true, desc = 'Space a from the prompt (the session goes on)' })
  end
end

-- Open the session in a tab: its own, if it has one. s needs short, config_dir, and
-- project and name for the winbar until the board's data has the session.
function M.attach(s)
  local win = find_win(s.short)
  if win then
    vim.api.nvim_set_current_win(win)
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
  -- Ctrl+Z in Claude detaches: the client exits, and the tab goes with it; the board is next
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    once = true,
    callback = function()
      vim.b[buf].control_ended = true
      update_winbars()
      if vim.v.event.status == 0 then
        vim.schedule(function()
          leave(buf)
        end)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TermEnter' }, {
    buffer = buf,
    callback = function()
      last_key = s.short
    end,
  })
  vim.b[buf].footer = FOOTER
  unwatch = unwatch or data.watch(update_winbars)
  -- Closing the tab (:tabclose, Ctrl-W c) only hides a terminal buffer, and its
  -- `claude attach` would go on: wipe it, which detaches the client, not the session
  vim.api.nvim_create_autocmd('BufHidden', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end)
    end,
  })
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

-- Ctrl+6 on the board: the session window we were in last
function M.back()
  local win = last_key and find_win(last_key)
  for _, w in ipairs(vim.api.nvim_list_wins()) do -- the last one is gone: any other that is alive
    local b = vim.api.nvim_win_get_buf(w)
    win = win or (vim.b[b].control_session and not vim.b[b].control_ended and w) or nil
  end
  if not win then
    return vim.notify('No session window yet: Enter on a session opens one', vim.log.levels.INFO)
  end
  vim.api.nvim_set_current_win(win)
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

-- Run `claude --bg …` in a folder, then open the session it printed
local function background(config, root, args, label)
  vim.system(claude(config, '--bg', unpack(args)), { cwd = root, text = true }, function(out)
    vim.schedule(function()
      local short = (out.stdout or ''):match 'backgrounded · (%w+)'
      if not short then
        return vim.notify('claude --bg failed: ' .. vim.trim((out.stderr or '') .. (out.stdout or '')), vim.log.levels.ERROR)
      end
      M.attach { short = short, config_dir = config, project = vim.fs.basename(root), name = label or short }
    end)
  end)
end

-- Start a background session in a folder and open it
function M.start(root)
  vim.notify('Starting a Claude session in ' .. vim.fs.basename(root) .. '…')
  background(default_config(), root, {})
end

-- Continue a past session (an entry of sessions.py's index: id, cwd, config_dir, title):
-- its open tab or live session if it has one, else a background session resumed from its
-- own folder under its own account
function M.resume(entry)
  for _, s in ipairs(data.last() and data.last().sessions or {}) do
    if s.id == entry.id then
      return M.open(s)
    end
  end
  if not (entry.cwd and vim.uv.fs_stat(entry.cwd)) then
    return vim.notify(('%s ran in %s, which is gone; it cannot be continued there'):format(entry.title, entry.cwd or '?'), vim.log.levels.WARN)
  end
  vim.notify('Continuing ' .. entry.title .. '…')
  background(entry.config_dir, entry.cwd, { '--resume', entry.id }, entry.title)
end

return M
