return {
  { -- Highlight, edit, and navigate code using static analysis
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate', -- Command to update parsers
    -- Load Treesitter early for highlighting/indentation as soon as a buffer opens
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      -- Text Objects dependency
      'nvim-treesitter/nvim-treesitter-textobjects',
      -- Optional: Context display
      -- 'nvim-treesitter/nvim-treesitter-context',
      -- Optional: Rainbow delimiters
      -- 'hiphish/nvim-ts-rainbow2',
      -- Or:
      -- 'HiPhish/rainbow-delimiters.nvim' -- More modern rainbow plugin
    },
    config = function()
      -- Main Treesitter configuration
      require('nvim-treesitter.configs').setup {
        -- A list of parser names, or "all" (may be slow)
        ensure_installed = {
          'bash',
          'c',
          'comment', -- Basic comments, useful for textobjects
          'css',
          'diff',
          'dockerfile',
          'go',
          'gomod',
          'gosum',
          'graphql',
          'html',
          'java', -- Added Java
          'javascript',
          'jsdoc',
          'json',
          'jsonc',
          'kotlin',
          'latex',
          'bibtex',
          'lua',
          'make',
          'markdown',
          'markdown_inline', -- Important for code blocks inside markdown
          'norg', -- Added Norg
          'python',
          'query', -- For editing Treesitter query files
          'regex',
          'rust',
          'scss',
          'sql',
          'terraform',
          'toml',
          'tsx',
          'typescript',
          'vim',
          'vimdoc',
          'yaml',
          'zig',
        },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: Set to false if you manage `ensure_installed` carefully.
        -- Set to true for convenience but potentially slower startup on first open of new filetypes.
        auto_install = true,

        -- Core features
        highlight = {
          enable = true,
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          -- additional_vim_regex_highlighting = false,
          additional_vim_regex_highlighting = { 'latex' }, -- For better LaTeX math, etc.
          -- Or disable slow languages: additional_vim_regex_highlighting = {"markdown"}
        },
        indent = {
          enable = true,
          -- Disable indentation for specific languages if needed
          -- disable = { "python" },
        },

        folding = true,

        -- Incremental selection configuration
        incremental_selection = {
          enable = true,
          keymaps = {
            -- Recommended defaults:
            -- init_selection = '<CR>', -- Start selection block
            -- node_incremental = '<CR>', -- Expand to larger node
            -- scope_incremental = '<TAB>', -- Expand to parent scope (less common)
            -- node_decremental = '<BS>', -- Shrink selection
            -- Your original config:
            init_selection = '<leader>i',
            node_incremental = '<leader>i',
            scope_incremental = false,
            node_decremental = '<bs>',
          },
        },

        -- == Text Objects Configuration ==
        -- Moved from the separate plugin spec into the main config
        textobjects = {
          -- SELECT (Visual Mode Text Objects) --
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj
            keymaps = {
              -- Assignment (e.g., variable = value)
              ['a='] = { query = '@assignment.outer', desc = 'Around assignment' },
              ['i='] = { query = '@assignment.inner', desc = 'Inside assignment value' },
              -- ['l='] = { query = '@assignment.lhs', desc = 'Assignment left-hand side' }, -- CAUSES LAG on 'l'
              -- ['r='] = { query = '@assignment.rhs', desc = 'Assignment right-hand side' }, -- CAUSES LAG on 'r'

              -- Parameters/Arguments (e.g., function(arg1, arg2))
              ['aa'] = { query = '@parameter.outer', desc = 'Around parameter/argument' },
              ['ia'] = { query = '@parameter.inner', desc = 'Inside parameter/argument' },

              -- Conditionals (e.g., if block)
              ['ai'] = { query = '@conditional.outer', desc = 'Around conditional' },
              ['ii'] = { query = '@conditional.inner', desc = 'Inside conditional' },

              -- Loops (e.g., for, while)
              ['al'] = { query = '@loop.outer', desc = 'Around loop' },
              ['il'] = { query = '@loop.inner', desc = 'Inside loop' },

              -- Function Calls (e.g., my_func())
              ['af'] = { query = '@call.outer', desc = 'Around function call' },
              ['if'] = { query = '@call.inner', desc = 'Inside function call arguments' },

              -- Function Definitions (e.g., function my_func() ... end)
              ['am'] = { query = '@function.outer', desc = 'Around function/method definition' },
              ['im'] = { query = '@function.inner', desc = 'Inside function/method definition body' },

              -- Class Definitions (e.g., class MyClass ... end)
              ['ac'] = { query = '@class.outer', desc = 'Around class definition' },
              ['ic'] = { query = '@class.inner', desc = 'Inside class definition body' },

              -- Comments (Requires 'comment' parser)
              ['a/'] = { query = '@comment.outer', desc = 'Around comment' }, -- Useful general comment object
              ['i/'] = { query = '@comment.inner', desc = 'Inside comment' },

              -- Code Blocks (Your custom ones - keep them!)
              ['ib'] = { query = '@code_cell.inner', desc = 'Inside code block' },
              ['ab'] = { query = '@code_cell.outer', desc = 'Around code block' },

              -- You can add more custom ones based on your *.scm files!
              -- Example for lua field from your query:
              ['a:'] = { query = '@assignment.outer', desc = 'Around lua field assignment' }, -- Same as a= generally
              ['i:'] = { query = '@assignment.inner', desc = 'Inside lua field assignment' }, -- Same as i= generally
              -- ['l:'] = { query = '@assignment.lhs', desc = 'Lua field key' }, -- CAUSES LAG on 'l'
              -- ['r:'] = { query = '@assignment.rhs', desc = 'Lua field value' }, -- CAUSES LAG on 'r'
            },
            -- You can also optionally define selection_modes map as {'@textobject': 'mode'}
            -- Eg {'@function.inner': 'v'} for selecting inside functions in visual mode instead of normal mode
            -- selection_modes = {
            --   ['@parameter.outer'] = 'v', -- Cursor position is outside the object VECANS
            --   ['@function.outer'] = 'V', -- Large objects are selecting in linewise mode
            -- },
            -- Include comments in checks for validity for text objects like `a=` or `ac`
            include_surrounding_whitespace = true,
          },

          -- SWAP (Normal Mode) --
          swap = {
            enable = true,
            swap_next = {
              ['<leader>na'] = { query = '@parameter.inner', desc = 'Swap parameter/argument with next' },
              ['<leader>nm'] = { query = '@function.outer', desc = 'Swap function/method with next' },
              ['<leader>sbl'] = { query = '@code_cell.outer', desc = 'Swap code block with next' }, -- Your custom key
            },
            swap_previous = {
              ['<leader>pa'] = { query = '@parameter.inner', desc = 'Swap parameter/argument with previous' },
              ['<leader>pm'] = { query = '@function.outer', desc = 'Swap function/method with previous' },
              ['<leader>sbh'] = { query = '@code_cell.outer', desc = 'Swap code block with previous' }, -- Your custom key
            },
          },

          -- MOVE (Normal Mode - Like `]` and `[` motions) --
          move = {
            enable = true,
            set_jumps = true, -- Set jumps in the jumplist on move
            goto_next_start = {
              [']f'] = { query = '@call.outer', desc = 'Next function call start' },
              [']m'] = { query = '@function.outer', desc = 'Next function/method definition start' },
              [']C'] = { query = '@class.outer', desc = 'Next class definition start' },
              [']i'] = { query = '@conditional.outer', desc = 'Next conditional start' },
              [']l'] = { query = '@loop.outer', desc = 'Next loop start' },
              [']a'] = { query = '@parameter.outer', desc = 'Next parameter start' }, -- Added parameter jump
              [']='] = { query = '@assignment.outer', desc = 'Next assignment start' }, -- Added assignment jump
              [']/'] = { query = '@comment.outer', desc = 'Next comment start' }, -- Added comment jump
              [']b'] = { query = '@code_cell.inner', desc = 'Next code block start' }, -- Your custom key

              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              -- [']s'] = { query = '@scope', query_group = 'locals', desc = 'Next scope' },
              -- [']z'] = { query = '@fold', query_group = 'folds', desc = 'Next fold' },
            },
            goto_next_end = {
              [']F'] = { query = '@call.outer', desc = 'Next function call end' },
              [']M'] = { query = '@function.outer', desc = 'Next function/method definition end' },
              -- [']C'] = { query = '@class.outer', desc = 'Next class definition end' },
              [']I'] = { query = '@conditional.outer', desc = 'Next conditional end' },
              [']L'] = { query = '@loop.outer', desc = 'Next loop end' },
              [']A'] = { query = '@parameter.outer', desc = 'Next parameter end' }, -- Added parameter jump
              [']='] = { query = '@assignment.outer', desc = 'Next assignment end' }, -- Added assignment jump
              [']/'] = { query = '@comment.outer', desc = 'Next comment end' }, -- Added comment jump
              [']B'] = { query = '@code_cell.inner', desc = 'Next code block end' }, -- Your custom key
            },
            goto_previous_start = {
              ['[f'] = { query = '@call.outer', desc = 'Previous function call start' },
              ['[m'] = { query = '@function.outer', desc = 'Previous function/method definition start' },
              ['[C'] = { query = '@class.outer', desc = 'Previous class definition start' },
              ['[i'] = { query = '@conditional.outer', desc = 'Previous conditional start' },
              ['[l'] = { query = '@loop.outer', desc = 'Previous loop start' },
              ['[a'] = { query = '@parameter.outer', desc = 'Previous parameter start' }, -- Added parameter jump
              ['[='] = { query = '@assignment.outer', desc = 'Previous assignment start' }, -- Added assignment jump
              ['[/'] = { query = '@comment.outer', desc = 'Previous comment start' }, -- Added comment jump
              ['[b'] = { query = '@code_cell.inner', desc = 'Previous code block start' }, -- Your custom key
            },
            goto_previous_end = {
              ['[F'] = { query = '@call.outer', desc = 'Previous function call end' },
              ['[M'] = { query = '@function.outer', desc = 'Previous function/method definition end' },
              -- ['[C'] = { query = '@class.outer', desc = 'Previous class definition end' },
              ['[I'] = { query = '@conditional.outer', desc = 'Previous conditional end' },
              ['[L'] = { query = '@loop.outer', desc = 'Previous loop end' },
              ['[A'] = { query = '@parameter.outer', desc = 'Previous parameter end' }, -- Added parameter jump
              ['[='] = { query = '@assignment.outer', desc = 'Previous assignment end' }, -- Added assignment jump
              ['[/'] = { query = '@comment.outer', desc = 'Previous comment end' }, -- Added comment jump
              ['[B'] = { query = '@code_cell.inner', desc = 'Previous code block end' }, -- Your custom key
            },
          },
        },
      }

      -- == Configure Repeatable Moves ==
      -- Enables repeating the last textobject move (like `]m`) with `;` and `,`
      -- Also enhances built-in f/F/t/T to be repeatable with ;/,
      pcall(function() -- Wrap in pcall in case the module path changes or is missing
        local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
        -- Repeat Treesitter motions:
        vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
        vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)
        -- Make builtin f/F/t/T repeatable with ;/,:
        vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f)
        vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F)
        vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t)
        vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T)
      end)

      -- Optional: Setup nvim-treesitter-context if installed
      -- pcall(require('treesitter-context').setup, { enable = true })
      -- Optional: Setup rainbow delimiters if installed
      -- pcall(require('rainbow-delimiters.setup').setup)
    end,
  },
}
