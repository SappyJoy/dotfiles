return {
  {
    'lervag/vimtex',
    lazy = false, -- Or ft = {"tex", "bib"}, but often useful to have it load early
    -- event = "VeryLazy", -- Or "BufReadPre *.tex", "BufNewFile *.tex"
    -- ft = {"tex", "bib", "cls", "sty"}, -- If you want it strictly on filetype
    config = function()
      -- Minimal vimtex configuration
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_latexmk = {
        options = {
          '-shell-escape', -- Often needed for certain packages/features
          '-verbose',
          '-file-line-error',
          '-synctex=1',
          '-interaction=nonstopmode',
          -- '-pdf', -- Use PDF output
          -- '-pdflatex="pdflatex -interaction=nonstopmode %O %S"',
        },
      }
      -- Optional: Disable vimtex's own completion if you prefer only LSP
      -- vim.g.vimtex_completion_enabled = 0

      -- Optional: if you want continuous compilation on save
      -- vim.g.vimtex_compiler_continuous_automatic = 1 -- Set to 0 to disable

      -- To enable forward search with <leader>lv (local leader followed by lv)
      -- and to make Zathura auto-refresh without stealing focus:
      vim.g.vimtex_view_zathura_options = '--synctex-forward 0:0:%f -x "nvim --headless -c \\"VimtexInverseSearch %{line} \'%{input}\'\\""'
      vim.g.vimtex_compiler_progname = 'nvr' -- For inverse search from Zathura to Nvim

      -- Your custom keymaps
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'tex',
        callback = function()
          local map = vim.keymap.set
          map('n', '<leader>tc', '<Plug>(vimtex-compile)', { desc = '[L]aTeX [C]ompile (VimTeX)', buffer = true, noremap = true, silent = true })
          map('n', '<leader>tv', '<Plug>(vimtex-view)', { desc = '[L]aTeX [V]iew (VimTeX)', buffer = true, noremap = true, silent = true })
          map('n', '<leader>tX', '<Plug>(vimtex-clean-full)', { desc = '[L]aTeX Clean Full (VimTeX)', buffer = true, noremap = true, silent = true })
          -- Add other mappings as needed
        end,
      })
    end,
  },
}
