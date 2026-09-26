return {

  -- {
  --   'jakewvincent/mkdnflow.nvim',
  --   enabled = true,
  --   config = function()
  --     local mkdnflow = require 'mkdnflow'
  --     mkdnflow.setup {}
  --   end,
  -- },
  {
    'epwalsh/obsidian.nvim',
    enabled = false,
    lazy = false,
    ft = 'markdown',
    event = {
      -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
      -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
      'BufReadPre ' .. vim.fn.expand '~/notes/vault-13/**/*.md',
      'BufNewFile ' .. vim.fn.expand '~/notes/vault-13/**/*.md',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
      'nvim-telescope/telescope.nvim',
      'nvim-treesitter/nvim-treesitter',
      'ibhagwan/fzf-lua',
    },
    -- keys = {
    --   { '<leader>nl', ':ObsidianLink<cr>', desc = 'obsidian [l]ink selection' },
    -- },
    config = function(_, opts)
      require('obsidian').setup(opts)
      local wk = require 'which-key'
      wk.add {
        {
          { '<leader>n', group = 'Notes' },
          { '<leader>nO', '<cmd>ObsidianOpen<cr>', desc = 'Open note' },
          { '<leader>nb', '<cmd>ObsidianBacklinks<cr>', desc = 'Backlinks' },
          {
            '<leader>nc',
            function()
              local day_of_week = os.date '%A'
              assert(type(day_of_week) == 'string')

              ---@type integer
              local offset_start
              if day_of_week == 'Monday' then
                offset_start = 0
              elseif day_of_week == 'Tuesday' then
                offset_start = -1
              elseif day_of_week == 'Wednesday' then
                offset_start = -2
              elseif day_of_week == 'Thursday' then
                offset_start = -3
              elseif day_of_week == 'Friday' then
                offset_start = -4
              elseif day_of_week == 'Saturday' then
                offset_start = -5
              elseif day_of_week == 'Sunday' then
                offset_start = -6
              end
              assert(offset_start)

              vim.cmd(string.format('ObsidianDailies %d %d', offset_start, offset_start + 6))
            end,
            desc = 'Current week',
          },
          {
            '<leader>nf',
            function()
              local day_of_week = os.date '%A'
              assert(type(day_of_week) == 'string')

              ---@type integer
              local offset_start
              if day_of_week == 'Monday' then
                offset_start = 0
              elseif day_of_week == 'Tuesday' then
                offset_start = -1
              elseif day_of_week == 'Wednesday' then
                offset_start = -2
              elseif day_of_week == 'Thursday' then
                offset_start = -3
              elseif day_of_week == 'Friday' then
                offset_start = -4
              elseif day_of_week == 'Saturday' then
                offset_start = -5
              elseif day_of_week == 'Sunday' then
                offset_start = -6
              end
              assert(offset_start)

              vim.cmd(string.format('ObsidianDailies %d %d', offset_start + 7, offset_start + 13))
            end,
            desc = 'Next week',
          },
          { '<leader>na', '<cmd>ObsidianToday<cr>', desc = 'Today note' },
          { '<leader>nd', '<cmd>ObsidianDailies -30 0<cr>', desc = 'Daily notes' },
          { '<leader>nl', '<cmd>ObsidianLinks<cr>', desc = 'Links' },
          { '<leader>nm', '<cmd>ObsidianTemplate<cr>', desc = 'Template' },
          { '<leader>nn', '<cmd>ObsidianNew<cr>', desc = 'New' },
          { '<leader>no', '<cmd>ObsidianQuickSwitch<cr>', desc = 'Quick switch' },
          { '<leader>np', '<cmd>ObsidianPasteImg<cr>', desc = 'Paste image' },
          { '<leader>nr', '<cmd>ObsidianRename<cr>', desc = 'Rename' },
          { '<leader>ns', '<cmd>ObsidianSearch<cr>', desc = 'Search' },
          { '<leader>nt', '<cmd>ObsidianTags<cr>', desc = 'Tags' },
          { '<leader>nw', '<cmd>ObsidianWorkspace<cr>', desc = 'Workspace' },
        },
      }

      wk.add {
        {
          mode = { 'v' },
          { '<leader>n', group = 'Notes' },
          {
            '<leader>ne',
            function()
              local title = vim.fn.input { prompt = 'Enter title (optional): ' }
              vim.cmd('ObsidianExtractNote ' .. title)
            end,
            desc = 'Extract text into new note',
          },
          {
            '<leader>nl',
            function()
              vim.cmd 'ObsidianLink'
            end,
            desc = 'Link text to an existing note',
          },
          {
            '<leader>nn',
            function()
              vim.cmd 'ObsidianLinkNew'
            end,
            desc = 'Link text to a new note',
          },
          {
            '<leader>nt',
            function()
              vim.cmd 'ObsidianLinkTags'
            end,
            desc = 'Tags',
          },
        },
      }
      -- vim.wo.conceallevel = 1
    end,
    opts = {
      workspaces = {
        {
          name = 'notes',
          path = '~/notes/vault-13/',
        },
        {
          name = 'prompts',
          path = '~/notes/prompts/',
        },
        {
          name = 'dota-analytics',
          path = '~/notes/dota-analytics/',
        },
      },
      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
        name = 'telescope.nvim', -- Перейти на telescope.nvim, когда решат https://github.com/nvim-telescope/telescope.nvim/issues/3337
        -- В итоге просто переименовал всё в lowercase
        note_mappings = {
          -- Create a new note from your query.
          new = '<C-x>',
          -- Insert a link to the selected note.
          insert_link = '<C-l>',
        },
        tag_mappings = {
          -- Add tag(s) to current note.
          tag_note = '<C-x>',
          -- Insert a tag at the current location.
          insert_tag = '<C-l>',
        },
      },

      -- notes_subdir = 'notes',
      sort_by = 'modified',
      -- sort_by = 'accessed',
      sort_reversed = true,
      exclude = { 'templates', 'Excalidraw', 'assets/draw' },
      -- open_notes_in = 'vsplit',
      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
        ['gf'] = {
          action = function()
            return require('obsidian').util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- create and toggle checkboxes
        ['<cr>'] = {
          action = function()
            local line = vim.api.nvim_get_current_line()
            if line:match '%s*- %[' then
              require('obsidian').util.toggle_checkbox()
            elseif line:match '%s*-' then
              vim.cmd [[s/-/- [ ]/]]
              vim.cmd.nohlsearch()
            end
          end,
          opts = { buffer = true },
        },
      },

      -- Optional, customize how names/IDs for new notes are created.
      note_id_func = function(title)
        -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
        -- In this case a note with the title 'My new note' will be given an ID that looks
        -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
        local suffix = ''
        if title ~= nil then
          -- If title is given, transform it into valid file name.
          suffix = title
        else
          -- If title is nil, just add 4 random uppercase letters to the suffix.
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        return suffix
      end,

      note_path_func = function(spec)
        local path
        -- This is equivalent to the default behavior.
        path = spec.dir / tostring(spec.id)
        return tostring(path) .. '.md'
      end,

      image_name_func = function()
        ---@type obsidian.Client
        local client = require('obsidian').get_client()

        local note = client:current_note()
        -- if note then
        --   return string.format('%s-', note.id)
        -- else
        return string.format('%s', os.time())
        -- end
      end,

      follow_url_func = function(url)
        -- Open the URL in the default web browser.
        -- vim.fn.jobstart { 'open', url } -- Mac OS
        vim.fn.jobstart { 'xdg-open', url } -- linux
      end,

      new_notes_location = 'notes_subdir',

      completion = {
        nvim_cmp = true,
        min_chars = 0,
      },

      templates = {
        folder = 'assets/templates',
        date_format = '%Y-%m-%d-%a',
        time_format = '%H:%M',
        substitutions = {},
      },

      daily_notes = {
        date_format = '%Y-%m-%d',
        folder = 'daily',
        alias_format = '%A %B %d, %Y',
        -- template = "nvim-daily.md",
      },

      ---@param note obsidian.Note
      note_frontmatter_func = function(note)
        -- Add the title of the note as an alias.
        -- if note.title then
        --   note:add_alias(note.title)
        -- end

        local out = { tags = note.tags }

        out['publish'] = false
        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and vim.tbl_count(note.metadata) > 0 then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,

      -- Disable UI to allow render-markdown.nvim to handle visuals (avoids conflicts)
      ui = {
        enable = false,
      },
    },
  },
}
