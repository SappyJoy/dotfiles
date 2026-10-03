-- orgmode, minimal (Markdown or org is Phase 8's trial): the agenda, capture into
-- ~/orgfiles, and the heading search (every TODO at once). Loads on .org files or
-- these keys; needs a C compiler for its grammar.
local orgfiles = vim.fn.expand '~/orgfiles'

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>o', group = 'org' } } } },
  {
    'nvim-orgmode/orgmode',
    enabled = vim.fn.executable 'cc' == 1,
    ft = 'org',
    dependencies = { 'nvim-orgmode/telescope-orgmode.nvim' },
    keys = {
      {
        '<leader>oa',
        function()
          require('orgmode').action 'agenda.prompt'
        end,
        desc = 'Agenda',
      },
      {
        '<leader>oc',
        function()
          require('orgmode').action 'capture.prompt'
        end,
        desc = 'Capture',
      },
      {
        '<leader>oh',
        function()
          require('telescope').extensions.orgmode.search_headings()
        end,
        desc = 'Headings (all TODOs)',
      },
      {
        '<leader>of',
        function()
          require('telescope.builtin').find_files { cwd = orgfiles }
        end,
        desc = 'Org files',
      },
    },
    opts = {
      org_agenda_files = { orgfiles .. '/**/*' },
      org_default_notes_file = orgfiles .. '/inbox.org',
      org_capture_templates = {
        t = { description = 'Task', template = '* TODO %?\n  %u', target = orgfiles .. '/inbox.org' },
        n = { description = 'Note', template = '* %?\n  %u', target = orgfiles .. '/inbox.org' },
        p = { description = 'LLM prompt', template = '* PROMPT %?\n  %U\n\n  ', target = orgfiles .. '/prompts.org' },
      },
    },
    config = function(_, opts)
      -- orgmode builds its grammar with tree-sitter-cli whenever it's on PATH, even
      -- where it can't run (Ubuntu 20.04): there, with cc
      if not require('parsers').cli_runs() then
        local install = require 'orgmode.utils.treesitter.install'
        install.compilers = vim.tbl_filter(function(c)
          return c ~= 'tree-sitter'
        end, install.compilers)
      end
      require('orgmode').setup(opts)
      require('telescope').load_extension 'orgmode'
    end,
  },
}
