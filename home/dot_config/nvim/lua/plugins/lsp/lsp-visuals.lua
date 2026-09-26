return {
  {
    'onsails/lspkind.nvim',
    opts = {},
  },
  {
    'hedyhli/outline.nvim',
    config = function(_, opts)
      require('outline').setup(opts)
      -- Keymap is defined in keys or handled by which-key group settings
      vim.keymap.set('n', '<leader>so', '<cmd>topleft Outline<cr>', { desc = 'Toggle [s]ymbols outline' })
    end,
    opts = {
      outline_window = {
        focus_on_open = false,
        width = 20,
        relative_width = true,
      },
    },
  },
  {
    -- This plugin is no longer needed in Neovim 0.11+
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    enabled = false,
  },
}
