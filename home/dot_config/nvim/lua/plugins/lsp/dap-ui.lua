return {
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    keys = {
      { '<F7>', function() require('dapui').toggle() end, desc = 'Toggle Debug UI' },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup {
        mappings = {
          expand = { '<CR>', '<2-LeftMouse>' },
          open = 'o',
          remove = 'd',
          edit = 'e',
          repl = 'r',
          toggle = 't',
        },
        layouts = {
          { elements = { 'breakpoints', 'stacks', 'scopes' }, size = 0.30, position = 'left' },
          { elements = { 'repl', 'watches' }, size = 0.25, position = 'bottom' },
        },
        floating = {
          border = 'rounded',
          mappings = { close = { 'q', '<Esc>' } },
        },
        controls = {
          enabled = true,
          element = 'repl',
          icons = {
            pause = '',
            play = '',
            step_into = '󰆹',
            step_over = '󰆷',
            step_out = '󰆸',
            step_back = '󰮏',
            run_last = '↻',
            terminate = '󰓙',
          },
        },
        render = {
          max_value_lines = 100,
          indent = 1,
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
    end,
  },
  {
    'theHamsta/nvim-dap-virtual-text',
    dependencies = { 'mfussenegger/nvim-dap' },
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      clear_on_continue = false,
      display_options = {
        colorscheme = "dark",
        variable = 'fg=DiagnosticInfo',
        reference = 'fg=DiagnosticHint',
        current_reference = 'fg=DiagnosticWarn',
      }
    }
  },
}
