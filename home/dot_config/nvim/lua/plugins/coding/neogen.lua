return {
  {
    'danymat/neogen',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    keys = {
      {
        '<leader>cd',
        function()
          require('neogen').generate()
        end,
        desc = 'Generate Docs (Neogen)',
      },
    },
    opts = {
      snippet_engine = 'luasnip',
      languages = {
        python = {
          template = {
            annotation_convention = 'google_docstrings', -- or 'numpydoc', 'reST'
          },
        },
      },
    },
  },
}
