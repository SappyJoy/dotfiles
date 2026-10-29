-- Every Claude session ever run, in Telescope (<leader>ar): search by title, project,
-- date or first prompt; Ctrl-G (Alt-G while typing is the same key in Insert) switches
-- to a search of everything said, <leader>aR starts there. Enter continues the session
-- in a tab (session.resume). The preview renders the conversation's Markdown copy as
-- notes are rendered (render-markdown): a heading over each prompt and reply, code in
-- colour, tool runs dimmed, the matching line marked in a search.
-- The index and the copies come from milestone-flow's sessions.py (cached by size and
-- offset, so a search opens in well under a second after the first run).
local data = require 'control_board.data'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'
local previewers = require 'telescope.previewers'

local M = {}

local ns = vim.api.nvim_create_namespace 'control_board_history'

-- the conversation as Markdown, at entry.lnum if it has one
local function conversation()
  return previewers.new_buffer_previewer {
    title = 'Conversation',
    define_preview = function(self, entry)
      conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        use_ft_detect = false,
        callback = function(bufnr)
          vim.bo[bufnr].filetype = 'markdown' -- treesitter and render-markdown attach
          for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
            if line:find '^%*⚙ ' then -- a tool run: *⚙ Bash ×2 · Read*
              vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, { end_col = #line, hl_group = 'Comment', priority = 200 })
            end
          end
          if entry.lnum and vim.api.nvim_win_is_valid(self.state.winid) then
            vim.api.nvim_buf_set_extmark(bufnr, ns, entry.lnum - 1, 0, { line_hl_group = 'TelescopePreviewLine' })
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { entry.lnum, 0 })
            vim.api.nvim_win_call(self.state.winid, function()
              vim.cmd 'normal! zz'
            end)
          end
        end,
      })
    end,
  }
end

local function script()
  local env = vim.env.MILESTONE_FLOW_SESSIONS
  if env and env ~= '' then
    return env
  end
  local board = data.script()
  return board and vim.fs.dirname(board) .. '/sessions.py'
end

-- done(index) with the sessions newest first, or nil after saying why
local function load(done)
  local path = script()
  if not (path and vim.uv.fs_stat(path)) then
    return vim.notify("milestone-flow's sessions.py not found: run `make marketplace` in the toolkit", vim.log.levels.ERROR)
  end
  vim.system({ 'python3', path, '--index' }, { text = true }, function(out)
    vim.schedule(function()
      local ok, index = pcall(vim.json.decode, out.stdout or '')
      if not ok then
        return vim.notify('sessions.py failed: ' .. vim.trim(out.stderr or ''), vim.log.levels.ERROR)
      end
      done(index)
    end)
  end)
end

local function resume(bufnr, entry_of)
  actions.close(bufnr)
  require('control_board.session').resume(entry_of(action_state.get_selected_entry()))
end

local function pick_titles(index, switch)
  local display = entry_display.create {
    separator = ' ',
    items = { { width = 10 }, { width = 14 }, { width = 28 }, { remaining = true } },
  }
  pickers
    .new({}, {
      prompt_title = 'Sessions (Ctrl-G: search what was said)',
      finder = finders.new_table {
        results = index,
        entry_maker = function(s)
          local day = os.date('%Y-%m-%d', s.last_ts)
          return {
            value = s,
            filename = s.text,
            ordinal = table.concat({ s.title, s.project, day, s.first_prompt }, ' '),
            display = function()
              return display { { day, 'Comment' }, s.project, s.title, { s.first_prompt, 'Comment' } }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = conversation(),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          resume(bufnr, function(e)
            return e.value
          end)
        end)
        map({ 'i', 'n' }, '<C-g>', function()
          actions.close(bufnr)
          switch()
        end)
        return true
      end,
    })
    :find()
end

local function pick_text(index, switch)
  local by_file = {}
  for _, s in ipairs(index) do
    by_file[s.text] = s
  end
  local dir = vim.fs.dirname(index[1].text)
  local display = entry_display.create { separator = ' ', items = { { width = 12 }, { width = 20 }, { remaining = true } } }
  pickers
    .new({}, {
      prompt_title = 'Search what was said (Ctrl-G: back to titles)',
      finder = finders.new_async_job {
        command_generator = function(prompt)
          if not prompt or prompt == '' then
            return nil
          end
          return { 'rg', '--line-number', '--no-heading', '--color=never', '--smart-case', '--max-count=20', '--fixed-strings', '--', prompt, dir }
        end,
        entry_maker = function(line)
          local file, lnum, text = line:match '^(.-):(%d+):(.*)$'
          local s = file and by_file[file]
          if not s then
            return nil
          end
          return {
            value = s,
            filename = file,
            lnum = tonumber(lnum),
            ordinal = line,
            display = function()
              return display { s.project, s.title, { vim.trim(text), 'Comment' } }
            end,
          }
        end,
      },
      sorter = require('telescope.sorters').empty(),
      previewer = conversation(),
      attach_mappings = function(bufnr, map)
        actions.select_default:replace(function()
          resume(bufnr, function(e)
            return e.value
          end)
        end)
        map({ 'i', 'n' }, '<C-g>', function()
          actions.close(bufnr)
          switch()
        end)
        return true
      end,
    })
    :find()
end

local function open(text_first)
  vim.notify 'Reading the sessions…'
  load(function(index)
    if #index == 0 then
      return vim.notify('No sessions found', vim.log.levels.WARN)
    end
    local function titles()
      pick_titles(index, function()
        pick_text(index, titles)
      end)
    end
    local function text()
      pick_text(index, titles)
    end
    if text_first then
      text()
    else
      titles()
    end
  end)
end

function M.pick()
  open(false)
end

function M.grep()
  open(true)
end

return M
