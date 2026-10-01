-- CSV and TSV: csvview aligns the columns on screen (the file stays as it is, and
-- stays editable); Tab / Shift+Tab jump between fields.
return {
  parsers = { 'csv', 'tsv' },
  plugins = {
    {
      'hat0uma/csvview.nvim',
      ft = { 'csv', 'tsv' },
      opts = {
        view = { display_mode = 'border' },
        keymaps = {
          jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
          jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
          textobject_field_inner = { 'if', mode = { 'o', 'x' } },
          textobject_field_outer = { 'af', mode = { 'o', 'x' } },
        },
      },
      config = function(_, opts)
        require('csvview').setup(opts)
        vim.api.nvim_create_autocmd('FileType', {
          pattern = { 'csv', 'tsv' },
          callback = function(args)
            require('csvview').enable(args.buf)
          end,
        })
        require('csvview').enable(0) -- the buffer that loaded it
      end,
    },
  },
}
