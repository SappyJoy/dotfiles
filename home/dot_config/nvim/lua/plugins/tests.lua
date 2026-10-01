-- Tests: neotest runs the test under the cursor, the file or all, and debugs one
-- through nvim-dap (<leader>td). Languages add their adapters in lang/
-- (test_adapters).
local function nt(fn)
  return function()
    fn(require 'neotest')
  end
end

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>t', group = 'tests' } } } },
  {
    'nvim-neotest/neotest',
    dependencies = { 'nvim-neotest/nvim-nio', 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    keys = {
      { '<leader>tt', nt(function(n)
        n.run.run()
      end), desc = 'Run the nearest test' },
      { '<leader>tf', nt(function(n)
        n.run.run(vim.fn.expand '%')
      end), desc = "Run the file's tests" },
      { '<leader>ta', nt(function(n)
        n.run.run(vim.uv.cwd())
      end), desc = 'Run all tests' },
      { '<leader>tl', nt(function(n)
        n.run.run_last()
      end), desc = 'Run the last again' },
      { '<leader>td', nt(function(n)
        n.run.run { strategy = 'dap' }
      end), desc = 'Debug the nearest test' },
      { '<leader>ts', nt(function(n)
        n.summary.toggle()
      end), desc = 'Summary panel' },
      { '<leader>to', nt(function(n)
        n.output.open { enter = true, auto_close = true }
      end), desc = "The test's output" },
      { '<leader>tO', nt(function(n)
        n.output_panel.toggle()
      end), desc = 'Output panel' },
      { '<leader>tw', nt(function(n)
        n.watch.toggle(vim.fn.expand '%')
      end), desc = 'Rerun the file on save' },
      { '<leader>tS', nt(function(n)
        n.run.stop()
      end), desc = 'Stop' },
    },
    config = function()
      local adapters = {}
      for _, lang in pairs(require('lang').all()) do
        if lang.test_adapters then
          vim.list_extend(adapters, lang.test_adapters())
        end
      end
      require('neotest').setup { adapters = adapters }
    end,
  },
}
