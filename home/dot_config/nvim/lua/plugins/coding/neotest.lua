return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      -- Adapters
      'nvim-neotest/neotest-python',
      'nvim-neotest/neotest-jest',
      'alfaix/neotest-gtest',
    },
    keys = {
      { '<leader>t', '', desc = '+test' },
      { '<leader>tt', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run File' },
      { '<leader>tr', function() require('neotest').run.run() end, desc = 'Run Nearest' },
      { '<leader>td', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug Nearest' },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle Summary' },
      { '<leader>to', function() require('neotest').output.open { enter = true, auto_close = true } end, desc = 'Show Output' },
      { '<leader>tO', function() require('neotest').output_panel.toggle() end, desc = 'Toggle Output Panel' },
      { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop' },
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-python' {
            dap = { justMyCode = false },
            -- runner = "pytest",
          },
          require 'neotest-jest' {
            jestCommand = 'npm test --',
            jestConfigFile = 'custom.jest.config.ts',
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
          require 'neotest-gtest' {},
        },
      }
    end,
  },
}
