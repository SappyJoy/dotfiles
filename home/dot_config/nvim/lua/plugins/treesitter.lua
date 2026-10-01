-- Treesitter (the `main` rewrite, nvim 0.12): parsers, highlighting and folds per
-- filetype; textobjects' ]f/[f moves and the queries mini.ai selects with; the
-- sticky context. Languages add their parsers in lang/.
-- Needs tree-sitter-cli >= 0.26.1 and a C compiler to build parsers.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false, -- main doesn't lazy-load (its README)
    build = ':TSUpdate',
    opts = {
      ensure = {
        'bash',
        'diff',
        'git_config',
        'git_rebase',
        'gitcommit',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'regex',
        'toml',
        'vim',
        'vimdoc',
        'yaml',
      },
    },
    config = function(_, opts)
      -- install what's missing once the UI is up; nothing is checked online at start
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        once = true,
        callback = function()
          local wanted = vim.list_extend(vim.deepcopy(opts.ensure), require('lang').list 'parsers')
          local have = require('nvim-treesitter').get_installed()
          local missing = vim.tbl_filter(function(p)
            return not vim.tbl_contains(have, p)
          end, wanted)
          if #missing > 0 and vim.fn.executable 'tree-sitter' == 1 then
            require('nvim-treesitter').install(missing)
          end
        end,
      })
      local vim_syntax = require('lang').list 'vim_syntax'
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter', { clear = true }),
        callback = function(args)
          if not vim.tbl_contains(vim_syntax, args.match) and pcall(vim.treesitter.start, args.buf) then
            vim.wo[0][0].foldmethod = 'expr'
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          end
        end,
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    opts = { move = { set_jumps = true } },
    keys = {
      {
        ']f',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
        end,
        mode = { 'n', 'x', 'o' },
        desc = 'Next function',
      },
      {
        '[f',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
        end,
        mode = { 'n', 'x', 'o' },
        desc = 'Previous function',
      },
    },
  },
  { 'nvim-treesitter/nvim-treesitter-context', event = 'VeryLazy', opts = { max_lines = 3 } },
}
