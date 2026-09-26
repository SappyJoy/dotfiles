-- lua/plugins/trouble.lua
return {
  {
    'folke/trouble.nvim',
    cmd = { 'TroubleToggle', 'Trouble' }, -- Lazy load on command
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- Optional for icons
    opts = {
      -- Use your preferred settings here, or leave empty for defaults
      position = 'bottom', -- Position of the list
      height = 10, -- Height of the list
      width = 50, -- Width of the list
      -- icons = vim.g.have_nerd_font, -- Use icons if Nerd Font is available
      mode = 'workspace_diagnostics', -- Default mode ("workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", etc.)
      fold_open = '', -- Arrow icons for folded items
      fold_closed = '',
      group = true, -- Group results by file
      padding = true, -- Add padding around the list
      action_keys = { -- Keymaps for actions in the Trouble list
        close = 'q',
        cancel = '<esc>',
        refresh = 'r',
        jump = { '<cr>', '<tab>' },
        open_split = { '<c-s>' },
        open_vsplit = { '<c-v>' },
        open_tab = { '<c-t>' },
        jump_close = { 'o' },
        toggle_mode = 'm',
        toggle_preview = 'P',
        hover = 'K',
        preview = 'p',
        close_folds = { 'zM', 'zm' },
        open_folds = { 'zR', 'zr' },
        toggle_fold = { 'zA', 'za' },
        previous = 'k',
        next = 'j',
      },
      auto_open = false, -- Auto open when diagnostics change
      auto_close = false, -- Auto close when there are no items
      auto_preview = true, -- Auto preview the selected item
      auto_fold = false, -- Auto fold single entries
      auto_jump = { 'lsp_definitions' }, -- Jump to item automatically for these modes
      signs = {
        error = '',
        warning = '',
        hint = '',
        information = '',
        other = '',
      },
      use_diagnostic_signs = false, -- Use diagnostic signs defined elsewhere (e.g., in lspconfig)
    },
    -- Although keys are in sap/keymaps.lua, defining the main toggle here
    -- helps ensure lazy-loading works correctly if the key is pressed before
    -- the command is manually run.
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>xs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>cl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
      {
        '<leader>xx',
        '<cmd>TroubleToggle<cr>',
        desc = 'Toggle Trouble',
      },
      {
        '<leader>xw',
        '<cmd>TroubleToggle workspace_diagnostics<cr>',
        desc = 'Workspace Diagnostics (Trouble)',
      },
      {
        '<leader>xd',
        '<cmd>TroubleToggle document_diagnostics<cr>',
        desc = 'Document Diagnostics (Trouble)',
      },
    },
  },
}
