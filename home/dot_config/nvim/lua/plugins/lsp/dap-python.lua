return {
  {
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = { 'mfussenegger/nvim-dap', 'jay-babu/mason-nvim-dap.nvim' },
    config = function()
      -- The adapter is automatically configured by mason-nvim-dap.
      -- We just need to call setup on dap-python to create the python-specific configurations.
      require('dap-python').setup()
    end,
  },
}
