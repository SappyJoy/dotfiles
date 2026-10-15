-- <leader>aw: the board's rows (needs you, sessions, projects) in a Telescope picker.
-- Search them; the preview shows a session's last messages, a review, a roadmap.
-- Enter does what Enter does on the board; p (Alt+p while typing) plays a review's recording
-- (a row with one is marked ▶).
local data = require 'control_board.data'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local previewers = require 'telescope.previewers'
local entry_display = require 'telescope.pickers.entry_display'

local M = {}

local ICON = { answer = '❓', review = '🚦', waiting = '☐', tour = '🧭', session = '⏳', project = '▪' }
local SESSION_ICON = { answer = '❓', working = '⏳', idle = '·' }

-- every row of the board, as { icon, play, project, title, detail, row }
local function entries(board)
  local found = {}
  local function add(icon, project, title, detail, row)
    local play = require('control_board.demo').playable(row) and '▶' or ''
    table.insert(found, { icon = icon, play = play, project = project, title = title, detail = detail, row = row })
  end
  for _, need in ipairs(board.needs) do
    add(ICON[need.kind], need.project, need.title, need.detail, need)
  end
  for _, s in ipairs(board.sessions) do
    local row = vim.tbl_extend('force', s, { kind = 'session', session = s.id })
    add(SESSION_ICON[s.activity], s.project, s.name, s.activity == 'answer' and s.detail or s.activity, row)
  end
  for _, p in ipairs(board.projects) do
    local current = p.current and (p.current.id .. ' ' .. p.current.title) or 'no milestone open'
    add(ICON.project, p.name, current, ('%d of %d done'):format(p.done, p.total), vim.tbl_extend('force', p, { kind = 'project' }))
  end
  return found
end

local function show(bufnr, lines, filetype)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].filetype = filetype or ''
  end
end

local previewer = previewers.new_buffer_previewer {
  title = 'Preview',
  define_preview = function(self, entry)
    local row = entry.value.row
    local bufnr = self.state.bufnr
    if row.kind == 'session' or row.kind == 'answer' then
      local id = row.id or row.session
      show(bufnr, { 'Loading…' })
      vim.system({ 'python3', data.script(), '--tail', id }, { text = true }, function(out)
        vim.schedule(function()
          local text = vim.trim(out.stdout or '')
          show(bufnr, vim.split(text ~= '' and text or row.detail or '', '\n'))
        end)
      end)
      return
    end
    local path = row.kind == 'project' and row.path .. '/ROADMAP.md' or row.path
    local read, lines = pcall(vim.fn.readfile, path)
    show(bufnr, read and lines or { path .. ' is gone' }, 'markdown')
    if row.line then
      pcall(vim.api.nvim_win_set_cursor, self.state.winid, { row.line, 0 })
    end
  end,
}

function M.pick()
  local board = data.last()
  if not board then
    return data.refresh(function(fresh, err)
      if fresh then
        M.pick()
      else
        vim.notify(err, vim.log.levels.ERROR)
      end
    end)
  end
  local display = entry_display.create {
    separator = ' ',
    items = { { width = 2 }, { width = 1 }, { width = 18 }, { width = 28 }, { remaining = true } },
  }
  pickers
    .new({}, {
      prompt_title = 'Claude: needs you, sessions, projects',
      finder = finders.new_table {
        results = entries(board),
        entry_maker = function(e)
          return {
            value = e,
            ordinal = table.concat({ e.project, e.title, e.detail }, ' '),
            display = function()
              return display { e.icon, { e.play, 'DiagnosticOk' }, e.project, e.title, { e.detail, 'Comment' } }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewer,
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          require('control_board').open_row(entry.value.row)
        end)
        local function play()
          local entry = action_state.get_selected_entry()
          actions.close(bufnr)
          require('control_board.demo').play_review(entry.value.row)
        end
        map('n', 'p', play) -- a review's recording
        map('i', '<M-p>', play)
        return true
      end,
    })
    :find()
end

return M
