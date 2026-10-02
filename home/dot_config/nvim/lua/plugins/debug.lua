-- Debugging: nvim-dap and dap-view (one panel: scopes, watches, breakpoints,
-- threads, REPL; it opens with a session and closes after; it also draws the values
-- next to the code). <leader>b sets a breakpoint; <leader>D is the debug mode, until Esc.
-- Languages add their adapters in lang/ (dap).
local function dap(fn, ...)
  local args = { ... }
  return function()
    require('dap')[fn](unpack(args))
  end
end

return {
  {
    'folke/which-key.nvim',
    opts = {
      spec = {
        {
          '<leader>D',
          function()
            require('which-key').show { keys = '<leader>D', loop = true }
          end,
          desc = 'Debug mode (sticky)',
        },
      },
    },
  },
  {
    'mfussenegger/nvim-dap',
    dependencies = { 'igorlfs/nvim-dap-view' },
    keys = {
      { '<leader>b', dap 'toggle_breakpoint', desc = 'Breakpoint' },
      { '<leader>Dc', dap 'continue', desc = 'Start / continue' },
      { '<leader>Dn', dap 'step_over', desc = 'Next line' },
      { '<leader>Di', dap 'step_into', desc = 'Step into' },
      { '<leader>Do', dap 'step_out', desc = 'Step out' },
      { '<leader>Dr', dap 'run_to_cursor', desc = 'Run to cursor' },
      { '<leader>Db', dap 'toggle_breakpoint', desc = 'Breakpoint' },
      {
        '<leader>DB',
        function()
          require('dap').set_breakpoint(vim.fn.input 'Stop when: ')
        end,
        desc = 'Conditional breakpoint',
      },
      {
        '<leader>De',
        function()
          require('dap-view').hover()
        end,
        desc = 'Value under cursor',
      },
      {
        '<leader>Dw',
        function()
          require('dap-view').add_expr()
        end,
        desc = 'Watch the word under cursor',
      },
      {
        '<leader>Du',
        function()
          require('dap-view').toggle()
        end,
        desc = 'Panel',
      },
      { '<leader>Dq', dap 'terminate', desc = 'Stop' },
    },
    config = function()
      local d = require 'dap'
      require('dap-view').setup {
        auto_toggle = true,
        virtual_text = { enabled = true },
        winbar = { default_section = 'scopes' }, -- the locals first
      }
      vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
      vim.fn.sign_define('DapStopped', { text = '➜', texthl = 'DiagnosticOk', linehl = 'Visual' })
      for _, lang in pairs(require('lang').all()) do
        if lang.dap then
          lang.dap(d)
        end
      end
    end,
  },
}
