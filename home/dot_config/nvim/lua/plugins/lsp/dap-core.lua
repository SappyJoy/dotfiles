return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'jbyuki/one-small-step-for-vimkind',
      'jay-babu/mason-nvim-dap.nvim',
    },
    keys = {
      { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint' },
      { '<leader>B', function()
          local dap = require 'dap'
          vim.ui.input({ prompt = 'Breakpoint Condition: ' }, function(condition)
            if condition and condition ~= '' then
              dap.toggle_breakpoint(condition)
            else
              dap.toggle_breakpoint()
            end
          end)
        end, desc = 'Toggle Conditional Breakpoint' },
      { '<F1>', function() require('dap').step_into() end, desc = 'Debug Step Into' },
      { '<F2>', function() require('dap').step_over() end, desc = 'Debug Step Over' },
      { '<F3>', function() require('dap').step_out() end, desc = 'Debug Step Out' },
      { '<F5>', function() require('dap').continue() end, desc = 'Debug Continue' },
      { '<F6>', function() require('dap').terminate() end, desc = 'Debug Terminate' },
      { '<F10>', function() require('osv').launch { port = 8086 } end, desc = 'Launch OSV Nvim Debugger' },
    },
    config = function()
      local dap = require 'dap'

      dap.adapters.nlua = function(callback, config)
        callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
      end

      dap.configurations.lua = {
        {
          type = 'nlua',
          request = 'attach',
          name = 'Attach to running Neovim instance',
        },
      }

      vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = 'DiagnosticError', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '❓', texthl = 'DiagnosticWarn', linehl = '', numhl = '' })
      vim.fn.sign_define('DapLogPoint', { text = '🪵', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '▶️', texthl = 'DiagnosticHint', linehl = 'Visual', numhl = '' })
    end,
  },
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = { 'williamboman/mason.nvim', 'mfussenegger/nvim-dap' },
    cmd = { 'DapContinue', 'DapToggleBreakpoint', 'DapStepInto', 'DapStepOver', 'DapStepOut', 'DapTerminate', 'DapInstall', 'DapUninstall' },
    opts = {
      ensure_installed = { 'bash-debug-adapter', 'codelldb', 'debugpy' },
      handlers = {},
    },
  },
}
