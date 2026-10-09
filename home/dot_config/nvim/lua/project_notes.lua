-- Project notes: the notes/ folder of the repo you are in, small linked notes that
-- Claude keeps (milestone-flow). <leader>p keys open, find and grep them, list the
-- notes that link to this one, make a new one, and show them in the browser (the fish
-- function `notes`). In a note, Enter follows a [[link]] as Quartz and obsidian.nvim
-- resolve it: the shortest path that ends in its name; to a new note if none does.
local M = {}

-- the notes/ of the repo the buffer's file (else the cwd) is in, if it has notes
local function notes_dir(buf, quiet)
  local root = vim.fs.root(buf or 0, '.git')
  local dir = root and root .. '/notes'
  if dir and vim.uv.fs_stat(dir .. '/index.md') then
    return dir
  end
  if not quiet then
    vim.notify('No project notes: ' .. (root and vim.fs.basename(root) .. ' has no notes/index.md' or 'not in a git repo'))
  end
end

-- the buffer's file and its name without .md, if it is a note in dir
local function this_note(dir, buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if vim.startswith(file, dir .. '/') and file:sub(-3) == '.md' then
    return file, vim.fn.fnamemodify(file, ':t:r')
  end
end

local function edit(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  -- a new note starts with its title, as every note does
  if vim.fn.filereadable(path) == 0 and vim.api.nvim_buf_line_count(0) == 1 and vim.fn.getline(1) == '' then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { '# ' .. vim.fn.fnamemodify(path, ':t:r'), '', '' })
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
  end
end

function M.index()
  local dir = notes_dir()
  if dir then
    edit(dir .. '/index.md')
  end
end

function M.find()
  local dir = notes_dir()
  if dir then
    require('telescope.builtin').find_files { cwd = dir, prompt_title = 'Project notes' }
  end
end

function M.grep()
  local dir = notes_dir()
  if dir then
    require('telescope.builtin').live_grep { cwd = dir, prompt_title = 'Grep the project notes' }
  end
end

function M.backlinks()
  local dir = notes_dir()
  if not dir then
    return
  end
  local _, name = this_note(dir)
  if not name then
    return vim.notify 'Not a project note'
  end
  -- [[name]], [[folder/name]], [[name.md]], [[name#heading]], [[name|text]], and
  -- [[name\|text]] in a table
  local escaped = name:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?{}|\\]', '\\%0')
  require('telescope.builtin').grep_string {
    cwd = dir,
    search = '\\[\\[([^\\]|#]*/)?' .. escaped .. '(\\.md)?(\\\\?[#|][^\\]]*)?\\]\\]',
    use_regex = true,
    prompt_title = 'Notes linking to ' .. name,
  }
end

function M.new()
  local dir = notes_dir()
  if dir then
    vim.ui.input({ prompt = 'New note: ' }, function(title)
      if title and title ~= '' then
        edit(dir .. '/' .. title .. '.md')
      end
    end)
  end
end

-- the journal note of the milestone with the highest number
function M.journal()
  local dir = notes_dir()
  if not dir then
    return
  end
  local latest, number = nil, -1
  for _, path in ipairs(vim.fn.glob(dir .. '/journal/M*.md', false, true)) do
    local n = tonumber(vim.fn.fnamemodify(path, ':t'):match '^M(%d+)')
    if n and n > number then
      latest, number = path, n
    end
  end
  if latest then
    edit(latest)
  else
    vim.notify 'No journal notes yet'
  end
end

-- this note's page (else the index) in the browser, through the fish function notes
local opening = false
function M.browser()
  local dir = notes_dir()
  if not dir then
    return
  end
  if opening then
    return vim.notify 'Still opening the notes: the first time, Quartz installs, for several minutes'
  end
  opening = true
  local file = this_note(dir)
  vim.notify 'Opening the notes in the browser…'
  vim.system({ 'fish', '-c', 'notes $argv', file }, { cwd = dir, text = true }, function(done)
    opening = false
    -- its address, or what went wrong
    local out = vim.trim((done.stdout or '') .. (done.code == 0 and '' or '\n' .. (done.stderr or '')))
    vim.schedule(function()
      vim.notify(out:match '[^\n]*$', done.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
    end)
  end)
end

-- the [[link]] under the cursor: its name (empty within the note) and heading
local function link_under_cursor()
  local line, col, from = vim.api.nvim_get_current_line(), vim.fn.col '.', 1
  while true do
    local first, last, target = line:find('%[%[(.-)%]%]', from)
    if not first then
      return
    end
    if col >= first and col <= last then
      -- in a table, the pipe is escaped: [[name\|text]]
      local name, heading = (target:gsub('\\|', '|')):match '^([^|#]*)#?([^|]*)'
      return name:gsub('%.md$', ''), heading
    end
    from = last + 1
  end
end

function M.follow()
  local dir = notes_dir()
  local name, heading = link_under_cursor()
  if not (dir and name) then
    return
  end
  if name ~= '' then
    local best
    for path, kind in vim.fs.dir(dir, { depth = math.huge }) do
      local rel = path:match '^(.*)%.md$'
      if kind == 'file' and rel and (rel == name or vim.endswith(rel, '/' .. name)) and (not best or #rel < #best) then
        best = rel
      end
    end
    local path = dir .. '/' .. (best or name) .. '.md'
    if path ~= vim.api.nvim_buf_get_name(0) then
      edit(path)
    end
  end
  if heading ~= '' then
    vim.fn.search('\\V\\^#\\+ ' .. vim.fn.escape(heading, '\\') .. '\\$', 'cw')
  end
end

local map = vim.keymap.set
map('n', '<leader>pi', M.index, { desc = 'Index' })
map('n', '<leader>pf', M.find, { desc = 'Find a note' })
map('n', '<leader>pg', M.grep, { desc = 'Grep the notes' })
map('n', '<leader>pb', M.backlinks, { desc = 'Notes linking here' })
map('n', '<leader>pn', M.new, { desc = 'New note' })
map('n', '<leader>pj', M.journal, { desc = 'Latest journal note' })
map('n', '<leader>po', M.browser, { desc = 'Open in the browser' })

-- Enter in a project note: follow the link under the cursor, else Enter as usual
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  pattern = '*/notes/*.md',
  callback = function(ev)
    local dir = notes_dir(ev.buf, true)
    if dir and this_note(dir, ev.buf) then
      map('n', '<CR>', function()
        return link_under_cursor() and '<cmd>lua require("project_notes").follow()<cr>' or '<CR>'
      end, { buffer = ev.buf, expr = true, desc = 'Follow the link' })
    end
  end,
})

return M
