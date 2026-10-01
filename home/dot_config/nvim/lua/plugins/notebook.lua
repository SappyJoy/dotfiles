-- Notebooks: jupytext shows an .ipynb as Python with `# %%` cells and writes it
-- back keeping its outputs; molten runs cells in a Jupyter kernel and draws the
-- outputs (images through snacks, in kitty). Opening a notebook starts the
-- project's kernel and brings back its saved outputs; saving writes molten's
-- outputs into the .ipynb. Cells, kernels and keys: lua/notebook.lua.
return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>j', group = 'notebook' } } } },
  {
    'goerz/jupytext.nvim',
    version = '0.2.*',
    lazy = false, -- it reads the .ipynb itself (BufReadCmd)
    opts = { format = 'py:percent' },
  },
  {
    'benlubas/molten-nvim',
    -- master: the snacks image provider (2025-05) came after the last release (v1.9.2)
    build = ':UpdateRemotePlugins',
    lazy = false, -- a remote plugin: its commands come from the manifest at start
    init = function()
      vim.g.molten_image_provider = vim.g.kitty_graphics and 'snacks.nvim' or 'none'
      vim.g.molten_virt_text_output = true
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_output_win_max_height = 30
    end,
    config = function()
      local group = vim.api.nvim_create_augroup('notebook', { clear = true })
      vim.api.nvim_create_autocmd('BufReadPost', {
        group = group,
        pattern = '*.ipynb',
        callback = function(args)
          require('notebook').attach(args.buf)
          vim.schedule(function()
            require('notebook').start_kernel(args.buf)
          end)
        end,
      })
      -- .py files with cells get the keys too (no kernel until you run one)
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'python',
        callback = function(args)
          if not args.file:match '%.ipynb$' and vim.fn.search('^# %%', 'nw') > 0 then
            require('notebook').attach(args.buf)
          end
        end,
      })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = group,
        pattern = '*.ipynb',
        callback = function(args)
          vim.b[args.buf].notebook_mtime = vim.uv.fs_stat(args.file) and vim.uv.fs_stat(args.file).mtime
        end,
      })
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        pattern = '*.ipynb',
        callback = function(args)
          require('notebook').export_after_write(args.buf, vim.b[args.buf].notebook_mtime)
        end,
      })
    end,
  },
}
