-- The Week section as text: week.py's data (week.lua) in, lines out, like render.lua.
-- Input: build(week, err, w, kit); kit = { fit, builder, section } from render.lua.
-- Output: { lines, spans, rows } with line numbers relative to the section's first line;
-- rows are a project's code line (kind growth: Enter opens the roadmap) and flagged files (Enter opens the file).
local M = {}

local SPARK = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
local NAME, SHARE = 16, 10
local FILES_SHOWN = 3

-- 73700000 -> 73.7M, 8200 -> 8.2k
local function short(n)
  if n >= 1e6 then
    return ('%.1fM'):format(n / 1e6)
  elseif n >= 1e4 then
    return ('%dk'):format(math.floor(n / 1e3 + 0.5))
  elseif n >= 1e3 then
    return ('%.1fk'):format(n / 1e3)
  end
  return tostring(n)
end

local function level(value, top)
  if value <= 0 or top <= 0 then
    return SPARK[1], false
  end
  return SPARK[math.max(1, math.min(8, math.ceil(value * 8 / top)))], true
end

local function weekday(day)
  local y, m, d = day:match '(%d+)-(%d+)-(%d+)'
  return os.date('%a', os.time { year = y, month = m, day = d, hour = 12 }):sub(1, 2)
end

-- 4500 -> 1h15m, 300 -> 5m, 40 -> 40s
local function span(seconds)
  if seconds >= 3600 then
    return ('%dh%02dm'):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
  elseif seconds >= 60 then
    return ('%dm'):format(math.floor(seconds / 60))
  end
  return ('%ds'):format(seconds)
end

-- waits.py's kinds, in the user's words
local WAIT_KIND = {
  permission = 'permission ask',
  question = 'question',
  refusal = 'auto mode denial',
  guard = 'guard refusal',
  review = 'review',
  idle = 'idle',
}

local function bar(share)
  local full = math.floor(share * SHARE + 0.5)
  return string.rep('█', full) .. string.rep('░', SHARE - full)
end

function M.build(week, err, w, kit)
  local lines, spans, rows = {}, {}, {}
  local function add(text)
    table.insert(lines, text)
    return #lines
  end
  local function dim(text)
    table.insert(spans, { add('   ' .. text), 0, 3 + #text, 'ControlBoardDim' })
  end
  kit.section(lines, spans, 'Week', nil, w)
  if not week then
    dim(err and ('no data: ' .. vim.trim(err):gsub('%s+', ' ')) or 'Loading…')
    return { lines = lines, spans = spans, rows = rows }
  end

  -- tokens per project: share bar, a spark per day (scaled to the project's best day)
  local tokens = week.tokens
  local head = kit.builder(#lines + 1, spans)
  head.add(' ' .. kit.fit('Tokens', NAME + 3), 'ControlBoardProject')
  head.add(kit.fit(short(tokens.total), 7), nil)
  head.add(string.rep(' ', SHARE + 6))
  for _, day in ipairs(week.days) do
    head.add(weekday(day):sub(1, 1), 'ControlBoardDim')
  end
  add(head.text)
  for _, p in ipairs(tokens.projects) do
    local b = kit.builder(#lines + 1, spans)
    b.add('   ' .. kit.fit(p.name, NAME), 'ControlBoardProject')
    b.add(' ' .. kit.fit(short(p.total), 6))
    local share = tokens.total > 0 and p.total / tokens.total or 0
    b.add(bar(share), 'ControlBoardFill')
    b.add((' %3d%% '):format(math.floor(share * 100 + 0.5)), 'ControlBoardDim')
    local top = 0
    for _, n in ipairs(p.days) do
      top = math.max(top, n)
    end
    for _, n in ipairs(p.days) do
      local char, on = level(n, top)
      b.add(char, on and 'ControlBoardWork' or 'ControlBoardTrack')
    end
    add(b.text)
  end
  if tokens.top_prompt then
    local t = tokens.top_prompt
    dim(('Costliest prompt: %s in %s, "%s"'):format(short(t.tokens), t.project, t.text))
  end

  -- the 5-hour windows, a bar each, a day after day; 80% and more is hot
  local by_account = {}
  for _, win in ipairs(week.windows or {}) do
    if win.kind == '5h' then
      by_account[win.account] = by_account[win.account] or {}
      table.insert(by_account[win.account], win)
    end
  end
  local accounts = vim.tbl_keys(by_account)
  table.sort(accounts)
  if #accounts == 0 then
    dim '5-hour windows: recorded from now on, as the status line saves them'
  end
  for _, account in ipairs(accounts) do
    local b = kit.builder(#lines + 1, spans)
    b.add(' ' .. kit.fit('5h ' .. account, NAME + 3), 'ControlBoardProject')
    for _, day in ipairs(week.days) do
      b.add(weekday(day):sub(1, 1), 'ControlBoardDim')
      local any = false
      for _, win in ipairs(by_account[account]) do
        if os.date('%Y-%m-%d', win.resets_at - 1) == day then
          any = true
          local char = level(win.pct, 100)
          b.add(char, win.pct >= 80 and 'ControlBoardHot' or 'ControlBoardFill')
        end
      end
      b.add(any and ' ' or '· ', 'ControlBoardDim')
    end
    add(b.text)
  end

  -- where sessions waited for the user (waits.py): the top three kinds by time
  local waits = week.waits
  if waits then
    local head2 = kit.builder(#lines + 1, spans)
    head2.add(' ' .. kit.fit('Waiting for you', NAME + 3), 'ControlBoardProject')
    if waits.count == 0 then
      head2.add('recorded from now on, by the milestone-flow hook', 'ControlBoardDim')
    else
      head2.add(('%d waits, %s'):format(waits.count, span(waits.seconds)), 'ControlBoardDim')
    end
    add(head2.text)
    for _, k in ipairs(waits.kinds or {}) do
      local b = kit.builder(#lines + 1, spans)
      b.add('   ' .. kit.fit(WAIT_KIND[k.kind] or k.kind, NAME), 'ControlBoardProject')
      b.add(' ' .. kit.fit(span(k.seconds), 7))
      local share = waits.seconds > 0 and k.seconds / waits.seconds or 0
      b.add(bar(share), 'ControlBoardFill')
      b.add((' %dx'):format(k.count), 'ControlBoardDim')
      add(b.text)
    end
  end

  -- milestones finished
  local done = {}
  for _, m in ipairs(week.milestones or {}) do
    if m.count > 0 then
      table.insert(done, ('%s %d'):format(m.project, m.count))
    end
  end
  dim('Milestones finished: ' .. (#done > 0 and table.concat(done, ' · ') or 'none'))

  -- code growth
  local grown = kit.builder(#lines + 1, spans)
  grown.add(' ' .. kit.fit('Code', NAME + 3), 'ControlBoardProject')
  grown.add('lines of code now, added and removed this week', 'ControlBoardDim')
  add(grown.text)
  for _, g in ipairs(week.growth or {}) do
    local b = kit.builder(#lines + 1, spans)
    b.add('   ' .. kit.fit(g.name, NAME), 'ControlBoardProject')
    b.add(' ' .. kit.fit(short(g.loc), 7))
    b.add(('+%s'):format(short(g.added)), 'ControlBoardWork')
    b.add(' ')
    b.add(('−%s'):format(short(g.removed)), 'ControlBoardAsk')
    rows[add(b.text)] = { kind = 'growth', path = g.path, name = g.name, project = g.name, project_path = g.path }
    local parts = {}
    for _, grew in ipairs(g.grew or {}) do
      table.insert(parts, ('%s +%s'):format(grew.part, short(grew.delta)))
    end
    for _, part in ipairs(g.new or {}) do
      table.insert(parts, ('new: %s'):format(part))
    end
    if #parts > 0 then
      dim('  ' .. table.concat(parts, ' · '))
    end
    for i, file in ipairs(g.big or {}) do
      if i > FILES_SHOWN then
        dim(('  … and %d more past the size limit'):format(#g.big - FILES_SHOWN))
        break
      end
      local f = kit.builder(#lines + 1, spans)
      f.add('     ⚠ ', 'ControlBoardAsk')
      f.add(kit.fit(file.path, math.max(20, w - 16)))
      f.add(('%d lines'):format(file.lines), 'ControlBoardDim')
      rows[add(f.text)] = { kind = 'file', path = g.path .. '/' .. file.path, project = g.name, project_path = g.path, title = file.path }
    end
  end
  return { lines = lines, spans = spans, rows = rows }
end

return M
