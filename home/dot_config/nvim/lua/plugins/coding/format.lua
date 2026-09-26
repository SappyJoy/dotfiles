return {
  { -- Autoformat
    'stevearc/conform.nvim',

    opts = {
      -- Map filetypes to specific formatters
      formatters_by_ft = {
        lua = { 'stylua' },
        cpp = { 'clang-format' },
        c = { 'clang-format' },
        cmake = { 'cmake_format' },
        python = { 'cbfmt', 'isort', 'black' },
        java = { 'google-java-format' },
        xml = { 'xmlformat' },
        sql = { 'sql_formatter' },
        -- Use the specific prettier config for markdown buffers (including jupytext ones)
        markdown = { 'cbfmt', 'prettier_markdown_stdin' },
        protobuf = { 'buf' },
        proto = { 'buf' },
        -- Run eslint_d to fix lint errors, then prettier for styling
        typescript = { 'eslint_d', 'prettierd', 'prettier' },
        typescriptreact = { 'eslint_d', 'prettierd', 'prettier' },
        javascript = { 'eslint_d', 'prettierd', 'prettier' },
        javascriptreact = { 'eslint_d', 'prettierd', 'prettier' },
        json = { 'prettierd', 'prettier' }, -- Added JSON
        yaml = { 'prettierd', 'prettier' }, -- Added YAML
        html = { 'prettierd', 'prettier' }, -- Added HTML
        css = { 'prettierd', 'prettier' }, -- Added CSS
        scss = { 'prettierd', 'prettier' }, -- Added SCSS
        kotlin = { 'ktfmt' },
        -- rust = { 'rustfmt' }, -- Added Rust
        go = { 'gofmt', 'goimports' }, -- Added Go
        -- Remove ipynb and jupyter, rely on markdown ft set by jupytext
        -- quarto = { 'cbfmt', 'isort', 'black' }, -- Keep if you format quarto files differently
        quarto = { 'cbfmt', 'prettier_markdown_stdin' }, -- Or treat quarto like markdown
        tex = { 'latexindent' },
        bib = { 'bibtex-tidy' }, -- If bibtex-tidy has a CLI conform can use
      },
      formatters = {
        -- Configure prettier to accept stdin and treat it as markdown
        -- We create a dedicated formatter definition for this case.
        prettier_markdown_stdin = {
          inherit = true, -- Inherit base command, etc. from prettier if defined elsewhere
          command = 'prettier', -- Ensure command is correct
          -- Crucial: Provide a fake filename to prettier so it uses the markdown parser
          args = { '--stdin-filepath', 'dummy.md' },
          stdin = true,
        },
        ktfmt = {
          inherit = true,
          prepend_args = { '--kotlinlang-style' },
        },
        latexindent = {
          -- See latexindent.pl -h for options
          -- Example: use localSettings.yaml for project-specific indent rules
          args = { '-l', '-m' }, -- -l: use localSettings.yaml if present, -m: modify in place
        },
        bibtex_tidy = {
          args = { '--tidy-comments', '--remove-empty-fields', '%filepath' },
        },

        -- Configure cbfmt (assuming it's codeblockfmt)
        -- Usually, cbfmt should handle stdin well, but if it also fails,
        -- you might need to configure it explicitly.
        -- Example (if needed):
        -- cbfmt = {
        --   command = "cbfmt",
        --   stdin = true,
        --   args = {}, -- Add args if needed to hint language, though usually auto-detects from ``` blocks
        -- }
      },
      notify_on_error = true, -- Keep true during debugging
    },
    -- Ensure the keymap is outside the opts table if it wasn't already
    config = function(_, opts)
      require('conform').setup(opts)
      vim.keymap.set({ 'n', 'v' }, '<leader>fm', function()
        require('conform').format {
          timeout_ms = 1000, -- Increase timeout if needed
          lsp_fallback = true,
        }
      end, { desc = '[F]or[m]at buffer' })
    end,
  },
}
