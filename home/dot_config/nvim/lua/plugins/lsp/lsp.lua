return {
  { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      -- Autocmd for LSP Attach (your existing code is good)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          -- map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
          map('gr', function()
            require('telescope.builtin').lsp_references { show_line = false }
          end, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ss', require('telescope.builtin').lsp_document_symbols, '[S]earch Document [S]ymbols')
          map('<leader>sw', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[S]earch [W]orkspace symbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          map('K', vim.lsp.buf.hover, 'Hover Documentation')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Toggle Inlay Hints (Neovim 0.10+)
          if vim.lsp.inlay_hint then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled {})
            end, '[T]oggle Inlay [H]ints')
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'single' })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      local home = os.getenv 'HOME'
      local workspace_path = home .. '/.local/share/nvim/jdtls-workspace/'
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      local workspace_dir = workspace_path .. project_name
      local lsp_servers = {
        -- gopls = {},
        lua_ls = {
          -- settings.Lua.workspace/runtime are handled by lazydev.nvim
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
            },
          },
        },
        jdtls = {}, -- Ensure jdtls is installed via Mason if you use this
        pyright = {},
        clangd = {
          filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            -- '--query-driver=/usr/bin/clang++,/home/huawei/src/work/HarmonyOS/ohos-src/prebuilts/**/bin/clang++,/home/huawei/src/work/HarmonyOS/ohos-src/prebuilts/**/bin/clang',
            '--query-driver=/usr/bin/clang*,/usr/bin/c++,/usr/bin/g++,/**/llvm/bin/clang*,/home/huawei/src/work/HarmonyOS/ohos-src/prebuilts/**/bin/clang*',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
            '--offset-encoding=utf-16',
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
          capabilities = {
            offsetEncoding = { "utf-16" }, -- Keep this to avoid Copilot conflicts
          },
        },
        rust_analyzer = {
          settings = { diagnostics = { enable = true } },
        },
        -- xmlformatter = {}, -- xmlformatter is a formatter, not an LSP. Install with mason-tool-installer
        -- sqls = {},
        eslint = {}, -- For eslint LSP, ensure 'eslint_d' or 'eslint-lsp' is installed via Mason
        ts_ls = {}, -- TypeScript/JavaScript LSP (formerly tsserver)
        kotlin_language_server = {},
        -- debugpy is a Debug Adapter, not an LSP. Install with mason-tool-installer or mason-nvim-dap.

        -- LaTeX LSPs
        texlab = {
          -- Example specific texlab settings (optional)
          settings = {
            texlab = {
              auxDirectory = './.aux', -- If you want aux files in a subdirectory
              bibtexFormatter = 'texlab', -- or "bibtex-tidy" if you configure it
              formatterLineLength = 80,
              forwardSearch = {
                executable = 'zathura',
                args = { '--synctex-forward', '%l:1:%f', '%p' },
              },
            },
          },
        },
        ltex = {
          -- filetypes for nvim-lspconfig to activate ltex
          filetypes = { 'tex', 'latex', 'bib', 'markdown', 'gitcommit', 'text', 'rmd', 'org' },
          settings = {
            ltex = {
              -- Internal ltex setting for which "sub-languages" or types it processes
              -- This list is from your :LspInfo, seems to be a default from ltex-ls itself now
              enabled = {
                'bibtex',
                'gitcommit',
                'markdown',
                'org',
                'tex',
                'restructuredtext',
                'rsweave',
                'latex',
                'quarto',
                'rmd',
                'context',
                'html',
                'xhtml',
                'mail',
                'plaintext',
              },
              language = 'ru-RU', -- Or 'ru'
              diagnosticSeverity = 'information', -- Or 'warning' to make them more prominent
              sentenceCacheSize = 2000,
              additionalRules = {
                enablePickyRules = true,
                motherTongue = 'ru',
              },
              -- Use your more robust dynamic dictionary or the simple one for now
              -- dictionary = (function()
              --   local files = {}
              --   for _, file in ipairs(vim.api.nvim_get_runtime_file('dict/*', true)) do
              --     local lang = vim.fn.fnamemodify(file, ':t:r')
              --     if lang ~= '' then -- Ensure lang is not empty
              --       local fullpath = vim.fs.normalize(file) -- Use vim.fs.normalize
              --       if files[lang] then
              --         table.insert(files[lang], ':' .. fullpath)
              --       else
              --         files[lang] = { ':' .. fullpath }
              --       end
              --     end
              --   end
              --   if files.default then
              --     for lang, _ in pairs(files) do
              --       if lang ~= 'default' and files[lang] then
              --         vim.list_extend(files[lang], files.default)
              --       end
              --     end
              --     files.default = nil -- Remove default after merging
              --   end
              --   -- Ensure the target language dictionary exists, even if empty, if specified in 'language'
              --   if not files['ru-RU'] and not files['ru'] then
              --     files['ru-RU'] = {}
              --   end
              --   return files
              -- end)(),
              -- Or simpler for testing:
              dictionary = {
                ['ru-RU'] = { "LaTeX", "BibTeX", "терминXYZ" },
              },

              -- dictionary = (function()
              --   -- For dictionary, search for files in the runtime to have
              --   -- and include them as externals the format for them is
              --   -- dict/{LANG}.txt
              --   --
              --   -- Also add dict/default.txt to all of them
              --   local files = {}
              --   for _, file in ipairs(vim.api.nvim_get_runtime_file('dict/*', true)) do
              --     local lang = vim.fn.fnamemodify(file, ':t:r')
              --     local fullpath = vim.fs.normalize(file, ':p')
              --     files[lang] = { ':' .. fullpath }
              --   end
              --
              --   if files.default then
              --     for lang, _ in pairs(files) do
              --       if lang ~= 'default' then
              --         vim.list_extend(files[lang], files.default)
              --       end
              --     end
              --     files.default = nil
              --   end
              --   return files
              -- end)(),

              -- Potentially useful: If ltex-ls has trouble finding java or LT
              -- java = { path = "/path/to/your/java" }, -- If not on PATH or non-standard
              -- LanguageTool path might be configurable too, check ltex-ls docs
            },
          },
        },
        -- 'ltex_ls_plus' was an option, stick to 'ltex' (ltex-ls) for now unless you have a specific reason
      }

      -- Define ALL tools to be *ENSURED INSTALLED* by mason-tool-installer
      local tools_to_ensure_installed = {
        -- === LSPs ===
        'lua-language-server',
        'jdtls',
        'pyright',
        'clangd',
        'rust-analyzer',
        'eslint-lsp',
        'kotlin-language-server',
        'texlab',
        'ltex-ls',
        'taplo', -- TOML LSP
        'marksman', -- Markdown LSP
        'typescript-language-server', -- JS/TS LSP

        -- === Formatters (Must match coding/format.lua) ===
        -- 'stylua', -- Lua
        'clang-format', -- C/C++
        'cmakelang', -- CMake
        'black', -- Python
        'isort', -- Python
        'google-java-format', -- Java
        'xmlformatter', -- XML
        'sql-formatter', -- SQL
        'prettier', -- JS/TS/JSON/YAML/HTML/CSS
        'prettierd', -- Prettier Daemon (Faster)
        'eslint_d', -- JS/TS Linter
        'buf', -- Protobuf
        'ktfmt', -- Kotlin
        -- 'rustfmt', -- Rust
        -- 'gofumpt', -- Go (stricter gofmt)
        -- 'goimports', -- Go
        'cbfmt', -- Markdown code block formatter
        'latexindent', -- LaTeX
        'bibtex-tidy', -- BibTeX

        -- === Linters (Must match coding/lint.lua) ===
        'markdownlint',
        'hadolint',
        'jsonlint',
        'codespell',

        -- === Debug Adapters (Must match lsp/dap-core.lua) ===
        'debugpy',
        'codelldb',
        'bash-debug-adapter',
      }
            --
      -- Setup Mason
      require('mason').setup()

      -- (Keep your mason-tool-installer setup as is)
      require('mason-tool-installer').setup {
        ensure_installed = tools_to_ensure_installed,
        auto_update = true,
        run_on_start = true,
      }

      -- Setup mason-lspconfig
      -- NOTE: In Nvim 0.11+, we strictly use this for ensuring installation mapping.
      -- We DO NOT use 'handlers' here anymore because that triggers the deprecated API.
      require('mason-lspconfig').setup({})

      -- Manually configure and enable servers using the new Nvim 0.11 API
      for server_name, server_config in pairs(lsp_servers) do
        -- Skip jdtls (if you handle it separately with nvim-jdtls)
        if server_name ~= 'jdtls' then
          -- 1. Merge your custom capabilities with the defaults
          server_config.capabilities = vim.tbl_deep_extend('force', capabilities, server_config.capabilities or {})

          -- 2. Define the configuration using vim.lsp.config (The New Way)
          -- This registers your custom 'cmd', 'settings', 'init_options', etc.
          vim.lsp.config(server_name, server_config)

          -- 3. Enable the server
          -- This tells Neovim to start this server for the matching filetypes
          vim.lsp.enable(server_name)
        end
      end
    end,
  },
}
