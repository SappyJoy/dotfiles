-- C, C++, CUDA: clangd, clang-format where the project has a .clang-format.
return {
  parsers = { 'c', 'cpp', 'cuda', 'cmake', 'make' },
  servers = {
    clangd = {
      cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders',
        '--fallback-style=llvm',
        -- compilers clangd may ask for their system headers (compile_commands.json
        -- names them). A project's own toolchain: CLANGD_FLAGS in its .nvim.lua
        -- (the cheatsheet has an example); clangd adds those flags to these.
        '--query-driver=/usr/bin/**',
      },
      init_options = { usePlaceholders = true, completeUnimported = true, clangdFileStatus = true },
    },
  },
  formatters = { c = { 'clang_format' }, cpp = { 'clang_format' }, cuda = { 'clang_format' } },
  formats_if = { '.clang-format', '_clang-format' },
  tools = { { 'clangd', need = 'unzip' }, { 'clang-format', need = 'python' }, { 'codelldb', need = 'unzip' } },
  -- codelldb (mason) runs a program you name: build it with debug info first
  dap = function(dap)
    dap.adapters.codelldb = { type = 'executable', command = 'codelldb' }
    local launch = {
      name = 'Launch a program',
      type = 'codelldb',
      request = 'launch',
      program = function()
        return vim.fn.input('Program: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
    }
    dap.configurations.c = { launch }
    dap.configurations.cpp = { launch }
    dap.configurations.cuda = { launch }
  end,
}
