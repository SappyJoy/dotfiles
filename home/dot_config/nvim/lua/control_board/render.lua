-- The board as text: the collector's data (data.lua) in, lines out, with highlight spans
-- and which row of the data each line stands for. Knows nothing about windows.
-- Input: render(data, opts); opts = { width, expanded = { [project] = true },
--          playable = function(row) -> true for a row that has a recording to play }.
-- Output: { lines = {...}, spans = { {lnum, from, to, group} },
--           rows = { [lnum] = row } } (the data's own rows: needs, sessions, projects);
--           lnum is 1-based, spans' columns are 0-based bytes.
local M = {}

local WINDOW = { five_hour = 5 * 3600, seven_day = 7 * 86400 }
local BAR = 18
local PROJECT, TITLE, TAG, AGE = 16, 24, 8, 4
local PLAY = '▶' -- in its own column after the icon: a review with a recording, which `p` plays
local ICON = { answer = '❓', review = '🚦', waiting = '☐', tour = '🧭', working = '⏳', idle = '·' }
local STATE = { answer = 'needs you', working = 'working', idle = 'idle' }
local FOOTER = ' ⏎ open  t tick  c comment  p play ▶  i inbox note  s new session  Tab more  r refresh  q close'

local function width_of(s)
  return vim.fn.strdisplaywidth(s)
end

-- s cut to w cells (with …) and padded to w
local function fit(s, w)
  s = s:gsub('%s+', ' ')
  if width_of(s) > w then
    local out, used = '', 0
    for i = 0, vim.fn.strchars(s) - 1 do
      local char = vim.fn.strcharpart(s, i, 1)
      if used + width_of(char) > w - 1 then
        break
      end
      out, used = out .. char, used + width_of(char)
    end
    s = out .. '…'
  end
  return s .. string.rep(' ', w - width_of(s))
end

local function age(seconds)
  local minutes = math.floor(seconds / 60)
  if minutes < 1 then
    return 'now'
  elseif minutes < 60 then
    return minutes .. 'm'
  elseif minutes < 48 * 60 then
    return math.floor(minutes / 60) .. 'h'
  end
  return math.floor(minutes / 1440) .. 'd'
end

-- 2h14m, or 10m under an hour
local function left(seconds)
  local minutes = math.floor(seconds / 60)
  return minutes >= 60 and ('%dh%02dm'):format(math.floor(minutes / 60), minutes % 60) or minutes .. 'm'
end

-- A line built from pieces, each with a highlight group; remembers where they are
local function builder(lnum, spans)
  local b = { text = '' }
  function b.add(s, group)
    if group and s ~= '' then
      table.insert(spans, { lnum, #b.text, #b.text + #s, group })
    end
    b.text = b.text .. s
    return b
  end
  return b
end

-- the pace bar of one window: filled up to the percentage, a tick where the time is
local function bar(b, window, name, now)
  b.add(name .. ' ')
  if not window then
    b.add(string.rep('░', BAR), 'ControlBoardTrack').add('   –  ').add('no data yet', 'ControlBoardDim')
    return
  end
  local remaining = window.resets_at - now
  local expired = remaining <= 0
  local pct = expired and 0 or math.min(window.pct, 100)
  local fill = math.floor(pct * BAR / 100 + 0.5)
  local span = WINDOW[name == '5h' and 'five_hour' or 'seven_day']
  local tick = expired and -1 or math.max(0, math.min(BAR - 1, math.floor((span - remaining) * BAR / span)))
  for i = 0, BAR - 1 do
    if i == tick then
      b.add('│', 'ControlBoardTick')
    elseif i < fill then
      b.add('█', pct >= 80 and 'ControlBoardHot' or 'ControlBoardFill')
    else
      b.add('░', 'ControlBoardTrack')
    end
  end
  b.add(('%4d%%  '):format(pct))
  if expired then
    b.add('reset', 'ControlBoardDim')
  elseif name == '5h' then
    b.add('resets in ' .. left(remaining), 'ControlBoardDim')
  else
    b.add('resets ' .. os.date('%a %H:%M', window.resets_at), 'ControlBoardDim')
  end
end

local function section(lines, spans, title, count, w)
  local text = ' ' .. title .. (count and (' (' .. count .. ')') or '') .. ' '
  table.insert(lines, text .. string.rep('─', math.max(0, w - width_of(text))))
  table.insert(spans, { #lines, 0, #lines[#lines], 'ControlBoardSection' })
end

local function milestone_text(m)
  if not m then
    return 'no milestone open'
  end
  local text = m.id .. (m.gate and ' 🚦 ' or ' ') .. m.title
  return m.status == 'review' and text .. ' · review' or text
end

local function progress(done, total)
  local cells = 13
  local full = total > 0 and math.floor(done * cells / total + 0.5) or 0
  return string.rep('█', full) .. string.rep('░', cells - full)
end

function M.render(data, opts)
  local w = math.max(64, math.min(opts.width or 90, 100))
  local now = data.now
  local lines, spans, rows = {}, {}, {}
  local function add(text)
    table.insert(lines, text)
    return #lines
  end
  local function add_row(row, icon, icon_group, project, title, detail, tag, since)
    local b = builder(#lines + 1, spans)
    local text_w = w - 1 - 3 - 2 - PROJECT - 1 - TITLE - 1 - TAG - 1 - AGE - 1
    b.add(' ' .. fit(icon, 2) .. ' ', icon_group)
    local play = opts.playable and opts.playable(row)
    b.add((play and PLAY or ' ') .. ' ', play and 'ControlBoardWork' or nil)
    b.add(fit(project, PROJECT) .. ' ', 'ControlBoardProject')
    b.add(fit(title, TITLE) .. ' ')
    b.add(fit(detail, text_w) .. ' ', 'ControlBoardDim')
    b.add(fit(tag, TAG) .. ' ', 'ControlBoardDim')
    b.add(string.rep(' ', AGE - width_of(since)) .. since, 'ControlBoardDim')
    rows[add(b.text)] = row
  end

  local head = builder(1, spans)
  head.add(' Claude Code', 'ControlBoardTitle')
  local clock = os.date('%a %d %b %H:%M', now)
  head.add(string.rep(' ', math.max(1, w - 12 - 1 - #clock)) .. clock, 'ControlBoardDim')
  add(head.text)

  section(lines, spans, 'Plan', nil, w)
  for _, account in ipairs(data.accounts) do
    for i, name in ipairs { '5h', '7d' } do
      local b = builder(#lines + 1, spans)
      b.add(' ' .. fit(i == 1 and account.label or '', 9) .. ' ', 'ControlBoardProject')
      bar(b, account[i == 1 and 'five_hour' or 'seven_day'], name, now)
      add(b.text)
    end
  end

  local counts = data.counts
  section(lines, spans, 'Needs you', counts.answer + counts.review + counts.waiting + (counts.tour or 0), w)
  if #data.needs == 0 then
    local n = add '   nothing waits for you'
    table.insert(spans, { n, 0, #lines[n], 'ControlBoardDim' })
  end
  -- the first waiting line of a project stands for its others, until it is expanded
  local waiting, shown = {}, {}
  for _, need in ipairs(data.needs) do
    waiting[need.project_path] = (waiting[need.project_path] or 0) + (need.kind == 'waiting' and 1 or 0)
  end
  for _, need in ipairs(data.needs) do
    local since = need.since and age(now - need.since) or ''
    if need.kind == 'tour' then -- a nudge, not a demand: the quiet colour
      add_row(need, ICON.tour, 'ControlBoardWait', need.project, need.title, need.detail, '', since)
    elseif need.kind ~= 'waiting' then
      add_row(need, ICON[need.kind] or '·', 'ControlBoardAsk', need.project, need.title, need.detail, '', since)
    elseif opts.expanded and opts.expanded[need.project_path] then
      add_row(need, ICON.waiting, 'ControlBoardWait', need.project, need.title, need.detail, '', since)
    elseif not shown[need.project_path] then
      shown[need.project_path] = true
      local more = waiting[need.project_path] - 1
      local tag = more > 0 and '+ ' .. more .. ' more' or ''
      add_row(need, ICON.waiting, 'ControlBoardWait', need.project, need.title, need.detail, tag, since)
    end
  end

  local order = { answer = 1, working = 2, idle = 3 }
  local sessions = vim.deepcopy(data.sessions)
  table.sort(sessions, function(a, b)
    if a.activity ~= b.activity then
      return order[a.activity] < order[b.activity]
    end
    return a.since < b.since
  end)
  section(lines, spans, 'Sessions', #sessions, w)
  for _, s in ipairs(sessions) do
    local detail = s.activity == 'answer' and s.detail or STATE[s.activity]
    local icon = ICON[s.activity]
    local group = s.activity == 'answer' and 'ControlBoardAsk' or s.activity == 'working' and 'ControlBoardWork' or 'ControlBoardDim'
    local row = vim.tbl_extend('force', s, { kind = 'session', session = s.id })
    add_row(row, icon, group, s.project or '', s.name, detail, s.tmux and 'tmux' or '', age(now - s.since))
  end

  section(lines, spans, 'Projects', nil, w)
  for _, p in ipairs(data.projects) do
    local b = builder(#lines + 1, spans)
    b.add(' ' .. fit(p.name, PROJECT + 3), 'ControlBoardProject')
    b.add(fit(milestone_text(p.current), w - 1 - PROJECT - 3 - 1 - 13 - 16 - 1) .. ' ')
    b.add(progress(p.done, p.total), 'ControlBoardFill')
    b.add(('  %d of %d done'):format(p.done, p.total), 'ControlBoardDim')
    rows[add(b.text)] = vim.tbl_extend('force', p, { kind = 'project' })
  end

  add ''
  table.insert(spans, { add(FOOTER), 0, #FOOTER, 'ControlBoardDim' })
  return { lines = lines, spans = spans, rows = rows }
end

return M
