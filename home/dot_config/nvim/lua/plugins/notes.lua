-- Notes: obsidian.nvim (the community fork) on the vaults in ~/notes. Today's
-- note, this week's and next week's, the inbox, search, links and backlinks (its
-- own language server); Enter follows a link, toggles or makes a checkbox, folds a
-- heading. It loads in a vault, on :Obsidian or on its keys, and only where the
-- vaults are. render-markdown draws the notes; img-clip pastes images.
local notes = vim.fn.expand '~/notes'

local workspaces = {}
for _, name in ipairs { 'vault-13', 'prompts', 'dota-analytics' } do
  if vim.fn.isdirectory(notes .. '/' .. name) == 1 then
    table.insert(workspaces, { name = name, path = notes .. '/' .. name })
  end
end

local function cmd(args)
  return '<cmd>Obsidian ' .. args .. '<cr>'
end

-- this week's (or next week's) dailies: Monday to Sunday as offsets from today
local function week(next)
  return function()
    local monday = 1 - tonumber(os.date '%u') + (next and 7 or 0)
    vim.cmd(('Obsidian dailies %d %d'):format(monday, monday + 6))
  end
end

-- the inbox (a stopgap until Phase 8's capture): vault-13's inbox.md, at its end
local function inbox()
  local path = notes .. '/vault-13/inbox.md'
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({ '# Inbox', '' }, path)
  end
  vim.cmd.edit(path)
  vim.cmd 'normal! G'
end

-- Loading costs ~16 ms (its picker and completion come with it), so a note opened
-- while nvim starts gets it once the first screen is up; obsidian then attaches to
-- the notes already open. A note opened later loads it at once.
local function load_obsidian()
  if package.loaded['obsidian'] then
    return
  end
  require('lazy').load { plugins = { 'obsidian.nvim' } }
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == 'markdown' and vim.startswith(vim.api.nvim_buf_get_name(buf), notes .. '/') then
      vim.api.nvim_exec_autocmds('FileType', { group = 'obsidian_setup', buffer = buf })
      if buf == vim.api.nvim_get_current_buf() then
        vim.api.nvim_exec_autocmds('BufEnter', { group = 'obsidian_setup', buffer = buf })
      end
    end
  end
end

local function on_note()
  if vim.v.vim_did_enter == 1 then
    return load_obsidian()
  end
  vim.api.nvim_create_autocmd('User', { pattern = 'VeryLazy', once = true, callback = load_obsidian })
end

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>n', group = 'notes' } } } },
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    enabled = #workspaces > 0,
    cmd = 'Obsidian',
    init = function()
      vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
        pattern = notes .. '/**.md',
        once = true,
        callback = on_note,
      })
    end,
    dependencies = { 'nvim-telescope/telescope.nvim' }, -- its picker, loaded first
    keys = {
      { '<leader>na', cmd 'today', desc = "Today's note" },
      { '<leader>nc', week(false), desc = "This week's notes" },
      { '<leader>nf', week(true), desc = "Next week's notes" },
      { '<leader>nd', cmd 'dailies -30 0', desc = 'Daily notes, last 30 days' },
      { '<leader>ni', inbox, desc = 'Inbox' },
      { '<leader>nn', cmd 'new', desc = 'New note' },
      { '<leader>no', cmd 'quick_switch', desc = 'Open a note' },
      { '<leader>ns', cmd 'search', desc = 'Search the notes' },
      { '<leader>nt', cmd 'tags', desc = 'Tags' },
      { '<leader>nb', cmd 'backlinks', desc = 'Backlinks' },
      { '<leader>nl', cmd 'links', desc = 'Links in this note' },
      { '<leader>nr', cmd 'rename', desc = 'Rename the note (links follow)' },
      { '<leader>nm', cmd 'template', desc = 'Insert a template' },
      { '<leader>nw', cmd 'workspace', desc = 'Switch vault' },
      { '<leader>nO', cmd 'open', desc = 'Open in the Obsidian app' },
      { '<leader>np', '<cmd>PasteImage<cr>', desc = 'Paste an image' },
      { '<leader>ne', ':Obsidian extract_note<cr>', mode = 'x', desc = 'Extract into a new note' },
      { '<leader>nl', ':Obsidian link<cr>', mode = 'x', desc = 'Link to a note' },
      { '<leader>nn', ':Obsidian link_new<cr>', mode = 'x', desc = 'Link to a new note' },
    },
    opts = {
      legacy_commands = false,
      workspaces = workspaces,
      picker = { name = 'telescope.nvim' },
      ui = { enable = false }, -- render-markdown draws
      statusline = { enabled = false }, -- ours counts words
      -- a note's file is named after its title (else 4 random letters), at the root
      note_id_func = function(title)
        if title and title ~= '' then
          return title
        end
        local id = ''
        for _ = 1, 4 do
          id = id .. string.char(math.random(65, 90))
        end
        return id
      end,
      new_notes_location = 'notes_subdir',
      templates = {
        folder = 'assets/templates',
        date_format = 'YYYY-MM-DD-ddd',
        time_format = 'HH:mm',
        substitutions = {
          -- a daily note's day ("Friday October 02, 2026"), from its id (YYYY-MM-DD):
          -- the template is filled before the note gets its alias
          day = function(ctx)
            local id = ctx.partial_note and tostring(ctx.partial_note.id) or ''
            local y, m, d = id:match '^(%d+)-(%d+)-(%d+)$'
            local t = y and os.time { year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 } or os.time()
            return require('obsidian.date').format(t, 'dddd MMMM DD, YYYY')
          end,
        },
      },
      daily_notes = {
        folder = 'daily',
        date_format = 'YYYY-MM-DD',
        alias_format = 'dddd MMMM DD, YYYY',
        default_tags = { 'daily-notes' },
        workdays_only = false,
        -- the day as a heading ({{day}} above), as the old plugin wrote it
        template = vim.fn.stdpath 'config' .. '/templates/daily.md',
      },
      -- tags, publish (the Memory site publishes `publish: true`), and the rest as is
      frontmatter = {
        func = function(note)
          local out = { tags = note.tags, publish = false }
          for k, v in pairs(note.metadata or {}) do
            out[k] = v
          end
          return out
        end,
      },
      checkbox = { order = { ' ', 'x' } },
      attachments = { folder = 'assets/imgs' },
    },
  },
}
