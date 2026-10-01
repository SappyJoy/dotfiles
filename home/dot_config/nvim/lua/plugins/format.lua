-- Formatting with conform. On save, only where the project formats (a lang/
-- formats_if file up the tree), and then only your changes: the lines in git's
-- hunks, so colleagues' unformatted lines stay as they are. Outside git, or in a new
-- file, the whole file is yours. Keys: <leader>fm your changes (Visual: the
-- selection), <leader>fM the whole file.

local function project_formats(buf)
  local markers = require('lang').format_markers()[vim.bo[buf].filetype]
  if markers == true then -- the language always formats (fish)
    return true
  end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  for _, marker in ipairs(markers or {}) do
    local file, pattern = marker, nil
    if type(marker) == 'table' then
      file, pattern = marker[1], marker[2]
    end
    local found = vim.fs.find(file, { path = dir, upward = true })[1]
    if found and (not pattern or table.concat(vim.fn.readfile(found), '\n'):find(pattern)) then
      return true
    end
  end
  return false
end

-- the changed line ranges, last first (formatting one keeps the others' numbers);
-- nil when the whole file counts as changed
local function changed_ranges(buf)
  local ok, gitsigns = pcall(require, 'gitsigns')
  local hunks = ok and vim.b[buf].gitsigns_head and gitsigns.get_hunks(buf)
  if not hunks then
    return nil
  end
  local ranges = {}
  for _, h in ipairs(hunks) do
    if h.added.count > 0 then
      local last = h.added.start + h.added.count - 1
      local width = #(vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1] or '')
      table.insert(ranges, 1, { start = { h.added.start, 0 }, ['end'] = { last, width } })
    end
  end
  return ranges
end

local function format_changes(buf)
  local conform = require 'conform'
  local ranges = changed_ranges(buf)
  if not ranges then
    return conform.format { bufnr = buf, timeout_ms = 2000 }
  end
  for _, range in ipairs(ranges) do
    conform.format { bufnr = buf, range = range, timeout_ms = 2000 }
  end
end

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>f', group = 'format' } } } },
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>fm',
        function()
          format_changes(0)
        end,
        desc = 'Format my changes',
      },
      {
        '<leader>fm',
        function()
          require('conform').format { timeout_ms = 2000 }
        end,
        mode = 'x',
        desc = 'Format the selection',
      },
      {
        '<leader>fM',
        function()
          require('conform').format { timeout_ms = 2000 }
        end,
        desc = 'Format the whole file',
      },
    },
    opts = function()
      return { formatters_by_ft = require('lang').map 'formatters', default_format_opts = { lsp_format = 'never' } }
    end,
    init = function()
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = vim.api.nvim_create_augroup('format-on-save', { clear = true }),
        callback = function(args)
          if project_formats(args.buf) then
            format_changes(args.buf)
          end
        end,
      })
    end,
  },
}
