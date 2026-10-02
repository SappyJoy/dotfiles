-- The statusline, no plugin. Left: mode, macro, git branch and changes, file.
-- Right: diagnostics, filetype, words (text), line:column and %.
-- Colors come from standard highlight groups, so any colorscheme works.
local M = {}

local modes = {
  n = { 'NORMAL', 'Function' },
  no = { 'O-PENDING', 'Function' },
  i = { 'INSERT', 'String' },
  v = { 'VISUAL', 'Statement' },
  V = { 'V-LINE', 'Statement' },
  ['\22'] = { 'V-BLOCK', 'Statement' },
  s = { 'SELECT', 'Statement' },
  S = { 'S-LINE', 'Statement' },
  ['\19'] = { 'S-BLOCK', 'Statement' },
  R = { 'REPLACE', 'DiagnosticError' },
  c = { 'COMMAND', 'Type' },
  t = { 'TERMINAL', 'Constant' },
}

local text_filetypes = require('ui.prose').filetypes

local function color(group, attr)
  return vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
end

-- Stl* groups: fg from a source group, bg from StatusLine
local function highlights()
  local bar = color('StatusLine', 'bg')
  local set = vim.api.nvim_set_hl
  for _, mode in pairs(modes) do
    set(0, 'StlMode' .. mode[2], { fg = color('Normal', 'bg'), bg = color(mode[2], 'fg'), bold = true })
  end
  for name, source in pairs {
    Add = 'GitSignsAdd',
    Change = 'GitSignsChange',
    Delete = 'GitSignsDelete',
    Error = 'DiagnosticError',
    Warn = 'DiagnosticWarn',
    Dim = 'Comment',
    Modified = 'DiagnosticWarn',
  } do
    set(0, 'Stl' .. name, { fg = color(source, 'fg'), bg = bar })
  end
end

local function hl(group, text)
  return ('%%#%s#%s%%*'):format(group, text)
end

local function mode()
  local m = vim.api.nvim_get_mode().mode
  local entry = modes[m] or modes[m:sub(1, 2)] or modes[m:sub(1, 1)] or { m, 'Function' }
  local out = hl('StlMode' .. entry[2], ' ' .. entry[1] .. ' ')
  local reg = vim.fn.reg_recording()
  return reg ~= '' and out .. hl('StlWarn', ' REC @' .. reg) or out
end

local function git(buf)
  local head = vim.b[buf].gitsigns_head
  if not head or head == '' then
    return ''
  end
  local out = '  ' .. head
  local s = vim.b[buf].gitsigns_status_dict or {}
  for _, k in ipairs { { 'added', '+', 'StlAdd' }, { 'changed', '~', 'StlChange' }, { 'removed', '-', 'StlDelete' } } do
    if (s[k[1]] or 0) > 0 then
      out = out .. ' ' .. hl(k[3], k[2] .. s[k[1]])
    end
  end
  return out
end

local function file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  name = name == '' and '[Scratch]' or vim.fn.fnamemodify(name, ':~:.')
  local flags = vim.bo[buf].modified and hl('StlModified', ' ●') or ''
  if vim.bo[buf].readonly then
    flags = flags .. hl('StlDim', ' RO')
  end
  return '  ' .. name:gsub('%%', '%%%%') .. flags
end

local function diagnostics(buf)
  local count = vim.diagnostic.count(buf)
  local out = {}
  if (count[vim.diagnostic.severity.ERROR] or 0) > 0 then
    table.insert(out, hl('StlError', 'E' .. count[vim.diagnostic.severity.ERROR]))
  end
  if (count[vim.diagnostic.severity.WARN] or 0) > 0 then
    table.insert(out, hl('StlWarn', 'W' .. count[vim.diagnostic.severity.WARN]))
  end
  return #out > 0 and table.concat(out, ' ') .. '  ' or ''
end

local function words(buf)
  local n = vim.b[buf].stl_words
  if not n then
    return ''
  end
  return (n < 1000 and n or ('%.1fk'):format(n / 1000)) .. ' words  '
end

function M.render()
  local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
  local ft = vim.bo[buf].filetype
  return table.concat {
    mode(),
    git(buf),
    file(buf),
    '%=',
    diagnostics(buf),
    ft ~= '' and hl('StlDim', ft) .. '  ' or '',
    words(buf),
    '%l:%v  %p%% ',
  }
end

local group = vim.api.nvim_create_augroup('ui.statusline', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = highlights })
-- the word count of text, kept per buffer (wordcount() reads the current one)
vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI', 'InsertLeave' }, {
  group = group,
  callback = function(args)
    if text_filetypes[vim.bo[args.buf].filetype] then
      vim.b[args.buf].stl_words = vim.fn.wordcount().words
    end
  end,
})
vim.api.nvim_create_autocmd({ 'ModeChanged', 'DiagnosticChanged', 'RecordingEnter', 'RecordingLeave' }, {
  group = group,
  callback = function()
    vim.schedule(vim.cmd.redrawstatus)
  end,
})
vim.api.nvim_create_autocmd('User', { group = group, pattern = 'GitSignsUpdate', command = 'redrawstatus' })

highlights()
vim.o.statusline = "%!v:lua.require'ui.statusline'.render()"

return M
