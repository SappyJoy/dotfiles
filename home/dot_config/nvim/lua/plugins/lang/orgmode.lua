return {
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter', lazy = true },
    },
    config = function()
      local ts_ok, parsers = pcall(require, 'nvim-treesitter.parsers')
      if ts_ok and not parsers.has_parser 'org' then
        vim.cmd 'TSInstall org'
      end

      -- 2. Основной сетап
      require('orgmode').setup {
        org_agenda_files = { '~/orgfiles/**/*' },
        org_default_notes_file = '~/orgfiles/inbox.org',
        org_capture_templates = {
          t = {
            description = 'Task',
            template = '* TODO %?\n  %u',
            target = '~/orgfiles/inbox.org',
          },
          n = {
            description = 'Note',
            template = '* %?\n  %u',
            target = '~/orgfiles/inbox.org',
          },
          p = {
            description = 'LLM Prompt',
            template = '* PROMPT %?\n  %U\n\n  ',
            target = '~/orgfiles/prompts.org',
          },
        },
        mappings = {
          org = {
            org_refile = nil,
          },
        },
      }

      -- 3. Настраиваем "Obsidian-поведение" через Autocmd
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'org',
        callback = function()
          local opts = { noremap = true, silent = true, buffer = true }

          -- Refile через Telescope (теперь точно сработает)
          vim.keymap.set('n', '<leader>or', '<cmd>Telescope orgmode refile_heading<CR>', opts)

          -- Enter в Normal Mode = переключить чекбокс (или выполнить действие под курсором)
          vim.keymap.set('n', '<CR>', function()
            require('orgmode').action 'org_mappings.org_ctrl_c_ctrl_c'
          end, opts)

          -- Enter в Insert Mode = умное создание нового пункта списка
          vim.keymap.set('i', '<CR>', function()
            local line = vim.api.nvim_get_current_line()
            -- Если строка начинается с "- [ ] " или "- [x] "
            if line:match '^%s*-%s*%[%s*[xX ]%s*%]' then
              return '\n- [ ] '
            -- Если строка начинается просто с "- " (список)
            elseif line:match '^%s*-%s+' then
              return '\n- '
            -- Иначе обычный Enter
            else
              return '\n'
            end
          end, { expr = true, buffer = true })
        end,
      })

      -- Which-Key лейблы
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add {
          { '<leader>o', group = 'Orgmode' },
          { '<leader>oa', desc = 'Agenda' },
          { '<leader>oc', desc = 'Capture' },
          {
            '<leader>of',
            function()
              require('telescope.builtin').find_files { cwd = '~/orgfiles', prompt_title = 'Org Files' }
            end,
            desc = 'Find files',
          },
          {
            '<leader>os',
            function()
              require('telescope.builtin').live_grep { cwd = '~/orgfiles', prompt_title = 'Org Grep' }
            end,
            desc = 'Search content',
          },
          { '<leader>oh', '<cmd>Telescope orgmode search_headings<CR>', desc = 'Search headings' },
          { '<leader>or', '<cmd>Telescope orgmode refile_heading<CR>', desc = 'Refile (Move)' },
        }
      end
    end,
  },
  {
    'nvim-orgmode/telescope-orgmode.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-orgmode/orgmode',
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('telescope').load_extension 'orgmode'
    end,
  },
}
