return {
  {
    'mfussenegger/nvim-dap',
    opts = function()
      local dap = require 'dap'
      
      -- Reuse the configuration for C, C++, and Rust
      for _, lang in ipairs { 'c', 'cpp', 'rust' } do
        dap.configurations[lang] = {
          {
            type = 'codelldb',
            request = 'launch',
            name = 'Launch file',
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
          },
        }
      end
    end,
  },
}
