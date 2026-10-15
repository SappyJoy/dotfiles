-- The control board: nvim as the place to run agentic coding. Plan usage, what waits
-- for you, the Claude sessions and the milestone-flow projects on one page (`cb` in a
-- shell, <leader>ab here); from it a session opens in a tab you can type in, a review
-- or a roadmap opens as a file, a Waiting on you line gets ticked, a note goes to a
-- project's Inbox. The facts come from milestone-flow's board.py (data.lua), the text
-- from render.lua, the session tabs from session.lua, the picker (<leader>aw) from
-- picker.lua. <leader>ac starts a background session in this project and attaches it.
local data = require 'control_board.data'
local render = require 'control_board.render'

local M = {}

local ns = vim.api.nvim_create_namespace 'control_board'
local expanded = {} -- projects whose Waiting on you lines are all shown
local rows = {} -- the board's buffer -> { [lnum] = row }
local LINKS = {
  ControlBoardTitle = 'Title',
  ControlBoardSection = 'Comment',
  ControlBoardDim = 'Comment',
  ControlBoardProject = 'Identifier',
  ControlBoardFill = 'DiagnosticWarn',
  ControlBoardHot = 'DiagnosticError',
  ControlBoardTrack = 'NonText',
  ControlBoardTick = 'Special',
  ControlBoardAsk = 'DiagnosticWarn',
  ControlBoardWait = 'DiagnosticInfo',
  ControlBoardWork = 'DiagnosticOk',
}

local function define_highlights()
  for name, link in pairs(LINKS) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

local function available(quiet)
  if data.script() then
    return true
  end
  if not quiet then
    vim.notify("The board needs milestone-flow's board.py: run `make marketplace` in the toolkit", vim.log.levels.WARN)
  end
end

-- ---- the board's buffer ----------------------------------------------------------

local function board_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].control_board then
      return buf
    end
  end
end

local function row_key(row)
  return row and (row.kind .. '\0' .. (row.id or row.project_path or row.path or row.project or '') .. '\0' .. (row.title or row.name or ''))
end

local function draw(buf, board)
  local win = vim.fn.win_findbuf(buf)[1] -- in any tab
  if not win or not board then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(win)[1]
  local was = row_key(rows[buf] and rows[buf][cursor])
  local out = render.render(board, { width = vim.api.nvim_win_get_width(win) - 1, expanded = expanded })
  rows[buf] = out.rows
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out.lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, span in ipairs(out.spans) do
    vim.api.nvim_buf_set_extmark(buf, ns, span[1] - 1, span[2], { end_col = span[3], hl_group = span[4] })
  end
  local target = math.min(cursor, #out.lines)
  for lnum, row in pairs(out.rows) do
    if was and row_key(row) == was then
      target = lnum
    end
  end
  vim.api.nvim_win_set_cursor(win, { target, 0 })
end

local function current_row()
  local buf = vim.api.nvim_get_current_buf()
  return rows[buf] and rows[buf][vim.api.nvim_win_get_cursor(0)[1]]
end

-- ---- what the keys do ------------------------------------------------------------

local function edit(path, line)
  vim.cmd('tab drop ' .. vim.fn.fnameescape(path))
  if not vim.bo.modified then
    vim.bo.autoread = true
    vim.cmd.checktime(vim.api.nvim_get_current_buf()) -- Claude may have changed it since it was loaded
  end
  if line then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd 'normal! zz'
  end
end

-- the project folder a row belongs to
local function project_path(row)
  return row.project_path or (row.kind == 'project' and row.path) or (row.path and vim.fs.dirname(row.path))
end

local function session_of(row)
  for _, s in ipairs(data.last() and data.last().sessions or {}) do
    if s.id == row.session then
      return s
    end
  end
end

-- Enter: what the row is, opened. Also what the picker does.
function M.open_row(row)
  if row.kind == 'answer' or row.kind == 'session' then
    local session = session_of(row)
    if session then
      return require('control_board.session').open(session)
    end
    vim.notify('That session is gone; refresh with r', vim.log.levels.WARN)
  elseif row.kind == 'review' or row.kind == 'waiting' then
    edit(row.path, row.line)
  elseif row.kind == 'project' then
    edit(row.path .. '/ROADMAP.md')
  end
end

local function buffer_of(path)
  local full = vim.fs.normalize(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.fs.normalize(vim.api.nvim_buf_get_name(buf)) == full then
      return buf
    end
  end
end

-- A file's lines changed and saved: fn gets the lines as they are on disk now (Claude
-- may have rewritten the file since the board was drawn) and returns the new ones, or
-- nothing to leave the file alone. A buffer with unsaved changes in the file stops it;
-- one without is reloaded, so it doesn't go stale. The files are LF without a BOM, as
-- Claude and nvim write them; a CRLF file would come back as LF.
local function change_file(path, fn)
  local held = buffer_of(path)
  if held and vim.bo[held].modified then
    vim.notify(vim.fs.basename(path) .. ' has unsaved changes in nvim: save or discard them first', vim.log.levels.WARN)
    return false
  end
  local read, lines = pcall(vim.fn.readfile, path)
  if not read then
    vim.notify('Could not read ' .. path, vim.log.levels.ERROR)
    return false
  end
  local changed = fn(lines)
  if not changed then
    return false
  end
  if not pcall(vim.fn.writefile, changed, path) then -- it raises when the folder isn't writable
    vim.notify('Could not write ' .. path, vim.log.levels.ERROR)
    return false
  end
  if held then
    vim.api.nvim_buf_call(held, function()
      vim.cmd 'silent! edit'
    end)
  end
  return true
end

local function tick(row)
  if row.kind ~= 'waiting' then
    return vim.notify('Only a Waiting on you line can be ticked', vim.log.levels.INFO)
  end
  local done = change_file(row.path, function(lines)
    if lines[row.line] ~= '- [ ] ' .. row.title then
      vim.notify('ROADMAP.md changed since the board was drawn; refreshing', vim.log.levels.WARN)
      data.refresh()
      return nil
    end
    lines[row.line] = '- [x] ' .. row.title
    return lines
  end)
  if done then
    vim.notify('Ticked in ' .. row.project .. "'s ROADMAP.md")
    data.refresh()
  end
end

-- c on a review: its file, a "Your reply" section at the end of that review, Insert mode
local function comment(row)
  if row.kind ~= 'review' then
    return vim.notify('Comments go on a review', vim.log.levels.INFO)
  end
  edit(row.path)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local heading = '^# Review: ' .. (row.title:match '^M%d+' or '') .. ' '
  local first = row.line
  if not (lines[first] or ''):match(heading) then -- the file changed since the board was drawn
    first = nil
    for i, line in ipairs(lines) do
      first = first or (line:match(heading) and i or nil)
    end
    if not first then
      data.refresh()
      return vim.notify('That review is gone from REVIEW.md; refreshing', vim.log.levels.WARN)
    end
  end
  local last = #lines
  for i = first + 1, #lines do
    if lines[i]:match '^# Review: ' then
      last = i - 1
      break
    end
  end
  while last > first and lines[last] == '' do
    last = last - 1
  end
  local reply
  for i = first, last do
    reply = lines[i] == '## Your reply' and i or reply
  end
  if not reply then
    vim.api.nvim_buf_set_lines(0, last, last, false, { '', '## Your reply', '', '' })
    reply = last + 2
  end
  vim.api.nvim_win_set_cursor(0, { reply + 1, 0 })
  vim.cmd 'startinsert'
end

local function choose_project(row, then_do)
  local path = row and project_path(row)
  if path then
    return then_do(path)
  end
  local projects = data.last() and data.last().projects or {}
  vim.ui.select(projects, {
    prompt = 'Project',
    format_item = function(p)
      return p.name
    end,
  }, function(p)
    if p then
      then_do(p.path)
    end
  end)
end

local function inbox_note(row)
  choose_project(row, function(path)
    vim.ui.input({ prompt = 'Inbox note for ' .. vim.fs.basename(path) .. ': ' }, function(text)
      if not text or text == '' then
        return
      end
      local file = path .. '/INBOX.md'
      if vim.fn.filereadable(file) == 0 then
        return vim.notify(vim.fs.basename(path) .. ' has no INBOX.md', vim.log.levels.WARN)
      end
      local done = change_file(file, function(lines)
        local last = #lines
        while last > 0 and lines[last] == '' do
          last = last - 1
        end
        local out = vim.list_slice(lines, 1, last)
        if last > 0 and not out[last]:match '^%s*%-' then
          table.insert(out, '') -- the first note of an Inbox that has only its intro
        end
        table.insert(out, '- ' .. text)
        return out
      end)
      if done then
        vim.notify('Added to ' .. vim.fs.basename(path) .. "'s Inbox")
      end
    end)
  end)
end

local function toggle(row)
  if row and row.kind == 'waiting' then
    expanded[row.project_path] = not expanded[row.project_path] or nil
    draw(vim.api.nvim_get_current_buf(), data.last())
  end
end

-- A board taller than its window used to shift under the cursor on every j (the config's
-- scrolloff is 10), repainting all of itself each time. Now the cursor goes down the
-- window and the board turns a page of half a window when the cursor leaves it. Both
-- options are set globally, so only while the board is the current buffer (a window-local
-- scrolloff would stay with the window when another buffer comes into it).
local function turn_pages(buf)
  local before
  local function on()
    before = before or { vim.go.scrolloff, vim.go.scrolljump }
    vim.go.scrolloff, vim.go.scrolljump = 0, -50 -- a negative scrolljump is a percentage of the window
  end
  local function off()
    if before then
      vim.go.scrolloff, vim.go.scrolljump = before[1], before[2]
      before = nil
    end
  end
  on()
  vim.api.nvim_create_autocmd('BufEnter', { buffer = buf, callback = on })
  vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWipeout' }, { buffer = buf, callback = off })
end

local function close()
  if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd.tabclose()
  else
    vim.cmd.quit()
  end
end

local function map_keys(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set('n', lhs, function()
      fn(current_row())
    end, { buffer = buf, nowait = true, desc = desc })
  end
  map('<CR>', function(row)
    return row and M.open_row(row)
  end, 'Open')
  map('t', function(row)
    return row and tick(row)
  end, 'Tick a Waiting on you line')
  map('c', function(row)
    return row and comment(row)
  end, 'Comment on a review')
  map('i', inbox_note, 'Inbox note')
  map('s', function(row)
    choose_project(row, require('control_board.session').start)
  end, 'New background session')
  map('<Tab>', toggle, 'Show all Waiting on you lines of the project')
  map('r', function()
    data.refresh()
  end, 'Refresh')
  map('q', close, 'Close the board')
end

-- ---- the commands ----------------------------------------------------------------

-- A tab for the board; nvim started just for it (`cb`) uses its empty first window
local function fresh_tab()
  local buf = vim.api.nvim_get_current_buf()
  local empty = vim.api.nvim_buf_get_name(buf) == ''
    and vim.bo[buf].buftype == ''
    and not vim.bo[buf].modified
    and vim.api.nvim_buf_line_count(buf) == 1
    and vim.fn.getline(1) == ''
  if empty and #vim.api.nvim_list_tabpages() == 1 and #vim.api.nvim_list_wins() == 1 then
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
    vim.api.nvim_buf_delete(buf, {})
  else
    vim.cmd.tabnew()
  end
end

function M.open()
  if not available() then
    return
  end
  define_highlights()
  local existing = board_buffer()
  if existing then
    local win = vim.fn.win_findbuf(existing)[1] -- in any tab
    if win then
      vim.api.nvim_set_current_win(win)
    end
    return data.refresh()
  end
  fresh_tab()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, 'control-board')
  vim.b[buf].control_board = true
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'controlboard'
  vim.wo.cursorline = true
  vim.wo.wrap = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.list = false
  vim.wo.fillchars = 'eob: '
  map_keys(buf)
  turn_pages(buf)
  local unwatch = data.watch(function(board)
    draw(buf, board)
  end)
  vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufHidden' }, {
    buffer = buf,
    once = true,
    callback = unwatch,
  })
  vim.api.nvim_create_autocmd('VimResized', { -- not buffer-local: the board may be in another tab
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return true
      end
      draw(buf, data.last())
    end,
  })
  if data.last() then
    draw(buf, data.last())
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { ' Claude Code', '', ' Loading…' })
  end
  data.refresh(function(board, err)
    if not board then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end)
end

function M.pick()
  if available() then
    require('control_board.picker').pick()
  end
end

-- a new background session in the project of this file (else the folder nvim is in),
-- opened in a tab
function M.new_session()
  local root = vim.fs.root(0, { 'ROADMAP.md', '.git' }) or vim.fn.getcwd()
  require('control_board.session').start(root)
end

-- The first page's line: "b  Control board" with the counts, once the data is in
function M.start_item()
  if not available(true) then
    return
  end
  local board = data.last()
  local counts = board and board.counts
  if not board then
    data.refresh(function(fresh)
      if fresh then -- a failed run would only make the page ask again, and again
        Snacks.dashboard.update()
      end
    end)
  end
  local line = 'Control board'
  if counts then
    line = line .. ('   ❓%d  🚦%d  ☐%d  ⏳%d working'):format(counts.answer, counts.review, counts.waiting, counts.working)
  end
  return { icon = '󰣖 ', key = 'b', desc = line, action = ':ControlBoard' }
end

vim.api.nvim_create_user_command('ControlBoard', M.open, { desc = 'The Claude control board' })
if vim.fn.executable 'claude' == 1 then
  vim.keymap.set('n', '<leader>ab', M.open, { desc = 'Control board' })
  vim.keymap.set('n', '<leader>aw', M.pick, { desc = 'Pick a session, review or project' })
  vim.keymap.set('n', '<leader>ac', M.new_session, { desc = 'New Claude session here (background)' })
end

return M
