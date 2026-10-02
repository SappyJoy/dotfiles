-- Notebooks: cells, kernels and keys for buffers with `# %%` cells (an .ipynb that
-- jupytext shows as Python, or such a .py file). Running goes through molten.
-- A cell starts at a `# %%` line (`# %% [markdown]`: a text cell) and ends before
-- the next one.
local M = {}

local MARK = '^# %%%%'

-- the cell around line lnum: header (0 if above the first marker), first, last
local function cell(buf, lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local header = 0
  for i = lnum, 1, -1 do
    if lines[i]:match(MARK) then
      header = i
      break
    end
  end
  local last = #lines
  for i = math.max(header, 0) + 1, #lines do
    if lines[i]:match(MARK) then
      last = i - 1
      break
    end
  end
  local first = header + 1
  while last > first and lines[last]:match '^%s*$' do
    last = last - 1
  end
  local markdown = header > 0 and lines[header]:match '%[markdown%]' ~= nil
  return { header = header, first = first, last = last, markdown = markdown }
end

local function headers(buf)
  local out = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match(MARK) then
      table.insert(out, i)
    end
  end
  return out
end

-- mini.ai: ij is a cell's code, aj the cell with its `# %%` line
function M.textobject(ai_type)
  local c = cell(0, vim.fn.line '.')
  local from = ai_type == 'a' and math.max(c.header, 1) or c.first
  return { from = { line = from, col = 1 }, to = { line = c.last, col = math.max(#vim.fn.getline(c.last), 1) } }
end

-- folds: each cell (and jupytext's header at the top) is one
function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match(MARK) or (lnum == 1 and line == '# ---') then
    return '>1'
  end
  return '='
end

function M.jump(dir)
  local lnum, target = vim.fn.line '.', nil
  local list = headers(0)
  if dir > 0 then
    for _, h in ipairs(list) do
      if h > lnum then
        target = h
        break
      end
    end
  else
    local here = cell(0, lnum).header
    for i = #list, 1, -1 do
      if list[i] < here then
        target = list[i]
        break
      end
    end
  end
  if target then
    vim.api.nvim_win_set_cursor(0, { math.min(target + 1, vim.fn.line '$'), 0 })
  end
  return target ~= nil
end

function M.new_cell(below)
  local c = cell(0, vim.fn.line '.')
  local at = below and c.last or math.max(c.header - 1, 0)
  vim.api.nvim_buf_set_lines(0, at, at, false, { '', '# %%', '' })
  vim.api.nvim_win_set_cursor(0, { at + 3, 0 })
end

function M.delete_cell()
  local c = cell(0, vim.fn.line '.')
  if M.initialized() then
    pcall(vim.cmd, 'MoltenDelete')
  end
  local last = vim.fn.line '$'
  for i = c.last + 1, last do -- up to the next marker
    if vim.fn.getline(i):match(MARK) then
      last = i - 1
      break
    end
  end
  vim.api.nvim_buf_set_lines(0, math.max(c.header, 1) - 1, last, false, {})
end

function M.initialized()
  local ok, status = pcall(require, 'molten.status')
  return ok and status.initialized() == 'Molten'
end

-- kernels ---------------------------------------------------------------------------

local function notebook_kernel(file)
  local ok, nb = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(file), '\n'))
  end)
  return ok and vim.tbl_get(nb, 'metadata', 'kernelspec', 'name') or nil
end

local function jupyter_data()
  return vim.env.JUPYTER_DATA_DIR or vim.fn.expand '~/.local/share/jupyter'
end

local function init(name, file)
  if M.initialized() then
    return
  end
  -- the kernel's connection file goes there; where Jupyter never ran, nothing
  -- creates the dir and the start fails
  vim.fn.mkdir(vim.env.JUPYTER_RUNTIME_DIR or (jupyter_data() .. '/runtime'), 'p')
  vim.cmd('MoltenInit ' .. name)
  if file:match '%.ipynb$' then
    pcall(vim.cmd, 'MoltenImportOutput')
  end
end

-- the project's .venv as a Jupyter kernel, registered once (in Jupyter's data dir)
local function venv_kernel(venv, file)
  local project = vim.fs.basename(vim.fs.dirname(venv))
  local name = 'venv-' .. project:lower():gsub('[^%w_-]', '-')
  local python = venv .. '/bin/python'
  local spec = jupyter_data() .. '/kernels/' .. name .. '/kernel.json'
  local ok, current = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(spec), '\n')).argv[1]
  end)
  if ok and current == python then
    return init(name, file)
  end
  local cmd = { python, '-m', 'ipykernel', 'install', '--user', '--name', name, '--display-name', project .. ' (.venv)' }
  vim.system(cmd, {}, function(r)
    vim.schedule(function()
      if r.code ~= 0 then
        return vim.notify('Registering the kernel failed:\n' .. r.stderr, vim.log.levels.ERROR)
      end
      init(name, file)
    end)
  end)
end

function M.start_kernel(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  -- once per buffer: reading a notebook fires BufReadPost twice (nvim, jupytext),
  -- and a second MoltenInit would open molten's kernel picker
  if M.initialized() or vim.b[buf].notebook_kernel_starting then
    return
  end
  vim.b[buf].notebook_kernel_starting = true
  local file = vim.api.nvim_buf_get_name(buf)
  local venv = vim.fs.find('.venv', { upward = true, path = vim.fs.dirname(file), type = 'directory' })[1]
  if not venv then
    local name = notebook_kernel(file)
    if name and vim.tbl_contains(vim.fn.MoltenAvailableKernels(), name) then
      return init(name, file)
    end
    return vim.cmd 'MoltenInit' -- molten's picker
  end
  vim.system({ venv .. '/bin/python', '-c', 'import ipykernel' }, {}, function(r)
    vim.schedule(function()
      if r.code == 0 then
        return venv_kernel(venv, file)
      end
      local root = vim.fs.dirname(venv)
      vim.ui.select({ 'Add ipykernel to the project (uv add --dev ipykernel)', 'Pick another kernel', 'Not now' }, {
        prompt = vim.fs.basename(root) .. "'s .venv has no ipykernel",
      }, function(_, choice)
        if choice == 1 then
          vim.notify 'uv add --dev ipykernel …'
          vim.system({ 'uv', 'add', '--dev', 'ipykernel' }, { cwd = root }, function(add)
            vim.schedule(function()
              if add.code ~= 0 then
                return vim.notify('uv add failed:\n' .. add.stderr, vim.log.levels.ERROR)
              end
              venv_kernel(venv, file)
            end)
          end)
        elseif choice == 2 then
          vim.cmd 'MoltenInit'
        end
      end)
    end)
  end)
end

-- the newest kernel some other program runs (VS Code, jupyter): its connection file
function M.connect()
  local newest, mtime
  for _, dir in ipairs { (vim.env.XDG_RUNTIME_DIR or '') .. '/jupyter/runtime', vim.fn.expand '~/.local/share/jupyter/runtime' } do
    for _, f in ipairs(vim.fn.glob(dir .. '/kernel-*.json', false, true)) do
      local t = vim.uv.fs_stat(f).mtime.sec
      if not mtime or t > mtime then
        newest, mtime = f, t
      end
    end
  end
  if not newest then
    return vim.notify('No running kernel found', vim.log.levels.WARN)
  end
  init(newest, vim.api.nvim_buf_get_name(0))
  vim.notify('Connected to ' .. vim.fs.basename(newest))
end

-- saving ----------------------------------------------------------------------------

-- molten's outputs into the .ipynb after a save. jupytext.nvim writes in the
-- background, so wait until the file has changed (its time differs from before the
-- save), then export, then tell jupytext.nvim the file's new time (b:mtime, its
-- own record), or its next save asks whether the file changed on disk.
function M.export_after_write(buf, before)
  local file = vim.api.nvim_buf_get_name(buf)
  local tries = 0
  local timer = assert(vim.uv.new_timer())
  timer:start(
    50,
    50,
    vim.schedule_wrap(function()
      tries = tries + 1
      local stat = vim.uv.fs_stat(file)
      local changed = stat and (not before or stat.mtime.sec ~= before.sec or stat.mtime.nsec ~= before.nsec)
      if not changed and tries < 200 then
        return
      end
      timer:stop()
      timer:close()
      if changed and vim.api.nvim_buf_is_valid(buf) and M.initialized() then
        vim.api.nvim_buf_call(buf, function()
          pcall(vim.cmd, 'MoltenExportOutput!')
          vim.b.mtime = vim.uv.fs_stat(file).mtime
        end)
      end
    end)
  )
end

-- running ---------------------------------------------------------------------------

function M.run_cell(advance)
  local c = cell(0, vim.fn.line '.')
  if not c.markdown and c.last >= c.first then
    if not M.initialized() then
      return M.start_kernel()
    end
    vim.fn.MoltenEvaluateRange(c.first, c.last)
  end
  if advance and not M.jump(1) then
    M.new_cell(true)
  end
end

function M.run_above()
  local here = cell(0, vim.fn.line '.')
  for _, h in ipairs(headers(0)) do
    if h > here.header then
      break
    end
    local c = cell(0, h)
    if not c.markdown and c.last >= c.first then
      vim.fn.MoltenEvaluateRange(c.first, c.last)
    end
  end
  if here.header == 0 or #headers(0) == 0 then
    vim.fn.MoltenEvaluateRange(here.first, here.last)
  end
end

function M.run_all()
  vim.api.nvim_win_call(0, function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { vim.fn.line '$', 0 })
    M.run_above()
    vim.api.nvim_win_set_cursor(0, pos)
  end)
end

-- keys for a buffer with cells --------------------------------------------------------

function M.attach(buf)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map({ 'n', 'i' }, '<S-CR>', function()
    vim.cmd 'stopinsert'
    M.run_cell(true)
  end, 'Run the cell, go to the next')
  map({ 'n', 'i' }, '<C-CR>', function()
    vim.cmd 'stopinsert'
    M.run_cell(false)
  end, 'Run the cell')
  map('n', ']j', function()
    M.jump(1)
  end, 'Next cell')
  map('n', '[j', function()
    M.jump(-1)
  end, 'Previous cell')
  map('n', '<leader>j<Down>', function()
    M.jump(1)
  end, 'Next cell')
  map('n', '<leader>j<Up>', function()
    M.jump(-1)
  end, 'Previous cell')
  map('n', '<leader>jr', function()
    M.run_cell(false)
  end, 'Run the cell')
  map('n', '<leader>ja', M.run_above, 'Run this and all above')
  map('n', '<leader>jA', M.run_all, 'Run all')
  map('n', '<leader>jo', function()
    M.new_cell(true)
  end, 'New cell below')
  map('n', '<leader>jO', function()
    M.new_cell(false)
  end, 'New cell above')
  map('n', '<leader>jd', M.delete_cell, 'Delete the cell')
  map('n', '<leader>js', '<cmd>noautocmd MoltenEnterOutput<cr>', 'Output in a float (again: enter it)')
  map('n', '<leader>jh', '<cmd>MoltenHideOutput<cr>', 'Hide the output')
  map('n', '<leader>jx', '<cmd>MoltenDelete<cr>', "Clear the cell's output")
  map('n', '<leader>ji', '<cmd>MoltenInterrupt<cr>', 'Interrupt')
  map('n', '<leader>jk', function()
    if M.initialized() then
      vim.cmd 'MoltenRestart!'
    else
      M.start_kernel(buf)
    end
  end, 'Start / restart the kernel')
  map('n', '<leader>jc', M.connect, 'Connect to a running kernel (VS Code, jupyter)')
  map('n', '<leader>jb', '<cmd>MoltenOpenInBrowser<cr>', 'Output in the browser')
  map('n', '<leader>J', function()
    require('which-key').show { keys = '<leader>j', loop = true }
  end, 'Notebook mode (sticky)')
  vim.b[buf].miniai_config = { custom_textobjects = { j = M.textobject } }
  -- cells fold (za), and jupytext's metadata header opens folded; the cursor
  -- starts at the first cell (once the window shows the buffer)
  vim.schedule(function()
    local win = vim.fn.bufwinid(buf)
    if win == -1 then
      return
    end
    vim.wo[win][0].foldmethod = 'expr'
    vim.wo[win][0].foldexpr = "v:lua.require'notebook'.foldexpr(v:lnum)"
    vim.api.nvim_win_call(win, function()
      if vim.fn.getline(1) == '# ---' then
        vim.cmd 'silent! 1foldclose'
      end
      local first = headers(buf)[1]
      if first and vim.fn.line '.' == 1 then
        vim.api.nvim_win_set_cursor(win, { first, 0 })
      end
    end)
  end)
end

return M
