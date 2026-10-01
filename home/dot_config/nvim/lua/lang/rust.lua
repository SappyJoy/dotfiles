-- Rust: rust-analyzer; rustfmt (from rustup) is Rust's convention, so every Cargo
-- project formats.
return {
  parsers = { 'rust', 'toml' },
  servers = { rust_analyzer = {} },
  formatters = { rust = { 'rustfmt' } },
  formats_if = { 'Cargo.toml' },
  tools = { 'rust-analyzer', { 'codelldb', need = 'unzip' } },
  -- codelldb on the debug build (cargo build first)
  dap = function(dap)
    dap.adapters.codelldb = { type = 'executable', command = 'codelldb' }
    dap.configurations.rust = {
      {
        name = 'Launch the debug build',
        type = 'codelldb',
        request = 'launch',
        program = function()
          local name = vim.fn.fnamemodify(vim.fs.root(0, 'Cargo.toml') or vim.fn.getcwd(), ':t')
          return vim.fn.input('Program: ', 'target/debug/' .. name, 'file')
        end,
        cwd = '${workspaceFolder}',
      },
    }
  end,
}
