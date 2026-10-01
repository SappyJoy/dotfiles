-- Documents: files that aren't text open as text, read-only: one table maps file
-- extensions to a converter. gx opens the original in its own viewer. A converter
-- that isn't installed, or a file that isn't what its extension says (.pth can be a
-- Python path file, .db anything), falls back to opening the file as it is.
local scripts = vim.fn.stdpath 'config' .. '/scripts/'
local M = {}

-- nvim's zip browser also claims office files (docx, xlsx, epub, … are zips inside);
-- it keeps the plain archives
vim.g.zipPlugin_ext = '*.zip,*.jar,*.whl,*.apk,*.aar,*.war,*.ear,*.xpi,*.kmz'

local function duckdb(sql)
  return function(path)
    local q = "'" .. path:gsub("'", "''") .. "'"
    return { 'duckdb', '-box', '-c', (sql:gsub('FILE', q)) }
  end
end

local function starts(magic)
  return function(head)
    return head:sub(1, #magic) == magic
  end
end

local zip_or_pickle = function(head)
  return head:sub(1, 2) == 'PK' or head:sub(1, 1) == '\128'
end

local media = {
  'mp3',
  'flac',
  'wav',
  'ogg',
  'opus',
  'm4a',
  'aac',
  'mp4',
  'mkv',
  'webm',
  'mov',
  'avi',
  'm4v',
}

-- ext: extensions; cmd(path) -> argv; fallback(path) -> argv, when cmd fails;
-- tool: what must be installed; is(head): the first bytes match (else the file opens
-- as it is); ft, wrap: the buffer's; viewer: gx's program (default xdg-open)
M.handlers = {
  {
    ext = { 'pdf' },
    cmd = function(p)
      return { 'pdftotext', '-layout', p, '-' }
    end,
    ft = 'text',
    wrap = true,
    viewer = 'zathura',
  },
  {
    ext = { 'docx', 'odt', 'rtf', 'epub', 'pptx' },
    cmd = function(p)
      return { 'pandoc', '-t', 'gfm', '--wrap=none', p }
    end,
    ft = 'markdown',
    wrap = true,
  },
  {
    -- every sheet through pandoc, as plain aligned columns (zl/zh scroll sideways);
    -- files it can't parse (openpyxl's, so pandas' to_excel) through DuckDB: the
    -- first sheet
    ext = { 'xlsx' },
    cmd = function(p)
      return { 'pandoc', '-t', 'plain', '--columns=100000', p }
    end,
    fallback = duckdb [[SELECT * FROM read_xlsx(FILE) LIMIT 1000]],
    wrap = false,
  },
  {
    ext = { 'parquet' },
    cmd = duckdb [[SELECT count(*) AS rows FROM FILE;
      SELECT column_name AS "column", column_type AS "type" FROM (DESCRIBE SELECT * FROM FILE);
      SELECT * FROM FILE LIMIT 100]],
    tool = 'duckdb',
  },
  {
    ext = { 'sqlite', 'sqlite3', 'db' },
    is = starts 'SQLite format 3\0',
    cmd = function(p)
      return { 'python3', scripts .. 'sqlite.py', p }
    end,
  },
  {
    ext = { 'npy', 'npz', 'safetensors', 'h5', 'hdf5' },
    cmd = function(p)
      return { 'uv', 'run', '-q', '--script', scripts .. 'tensors.py', p }
    end,
  },
  {
    ext = { 'pt', 'pth', 'ckpt', 'bin', 'pkl', 'pickle' },
    is = zip_or_pickle,
    cmd = function(p)
      return { 'uv', 'run', '-q', '--script', scripts .. 'tensors.py', p }
    end,
  },
  {
    ext = media,
    cmd = function(p)
      return { 'mediainfo', p }
    end,
  },
  {
    ext = { '7z', 'rar' },
    cmd = function(p)
      return { '7z', 'l', p }
    end,
  },
  {
    -- in kitty snacks.image draws images; elsewhere their metadata
    ext = { 'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'tiff' },
    when = function()
      return not vim.g.kitty_graphics
    end,
    cmd = function(p)
      return { 'exiftool', p }
    end,
    viewer = 'sxiv',
  },
}

local function open_outside(path, viewer)
  vim.system({ viewer or 'xdg-open', path }, { detach = true })
end

-- the file as it is: the normal read, then filetype detection
local function read_plain(buf, path)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent keepalt read ++edit ' .. vim.fn.fnameescape(path))
    vim.cmd 'silent 1delete _'
    vim.bo.modified = false
    vim.cmd 'filetype detect'
  end)
end

local function show(buf, lines, h)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].readonly = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].readonly = true
  vim.bo[buf].filetype = h.ft or 'document' -- 'document': no prose mode, no rendering
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].wrap = h.wrap or false
    vim.wo[win][0].spell = false
  end
  vim.b[buf].typewriter = false
end

local function open(args, h)
  local buf, path = args.buf, vim.fn.fnamemodify(args.file, ':p')
  local f = io.open(path, 'rb')
  local head = f and f:read(16) or ''
  if f then
    f:close()
  end
  local tool = h.tool or h.cmd(path)[1]
  if (h.is and not h.is(head)) or vim.fn.executable(tool) == 0 then
    if vim.fn.executable(tool) == 0 then
      vim.notify(tool .. " isn't installed: opened as it is", vim.log.levels.WARN)
    end
    return read_plain(buf, path)
  end
  vim.bo[buf].buftype = 'nowrite' -- :w can't overwrite the original with the text
  vim.bo[buf].swapfile = false
  vim.keymap.set('n', 'gx', function()
    open_outside(path, h.viewer)
  end, { buffer = buf, desc = 'Open the original' })
  show(buf, { 'Reading ' .. vim.fn.fnamemodify(path, ':t') .. ' with ' .. tool .. '…' }, {})
  local function run(cmd, on_fail)
    vim.system(cmd, { text = true }, function(r)
      vim.schedule(function()
        if r.code ~= 0 and on_fail then
          return on_fail()
        end
        local out = r.code == 0 and r.stdout or (r.stdout .. '\n' .. r.stderr)
        show(buf, vim.split(out:gsub('\n$', ''), '\n'), r.code == 0 and h or { wrap = true })
      end)
    end)
  end
  run(h.cmd(path), h.fallback and function()
    run(h.fallback(path))
  end)
end

local group = vim.api.nvim_create_augroup('documents', { clear = true })
for _, h in ipairs(M.handlers) do
  if not h.when or h.when() then
    local patterns = {}
    for _, ext in ipairs(h.ext) do
      table.insert(patterns, '*.' .. ext)
      table.insert(patterns, '*.' .. ext:upper())
    end
    vim.api.nvim_create_autocmd('BufReadCmd', {
      group = group,
      pattern = patterns,
      callback = function(args)
        open(args, h)
      end,
    })
  end
end

return M
