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
        -- .NET: without the ICU library (minimal systems) it aborts; it needs no locales
        marksman = { cmd_env = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = '1' } },
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
      }

      -- mason installs some tools with npm, into a Python venv or from a zip. Where
      -- those are missing (no node; Ubuntu's python3 without python3-venv; no unzip
      -- without sudo), skip the tools instead of failing at every start.
      -- `:checkhealth mason` shows what's missing.
      local has_npm = vim.fn.executable 'npm' == 1
      local has_unzip = vim.fn.executable 'unzip' == 1
      local python = vim.fn.resolve(vim.fn.exepath 'python3') -- e.g. /usr/bin/python3.14
      local has_venv = python ~= ''
        and vim.uv.fs_stat(vim.fs.dirname(vim.fs.dirname(python)) .. '/lib/' .. vim.fs.basename(python) .. '/ensurepip') ~= nil
      local function npm(name)
        return { name, condition = function() return has_npm end }
      end
      local function pip(name)
        return { name, condition = function() return has_venv end }
      end
      local function zip(name)
        return { name, condition = function() return has_unzip end }
      end

      -- Define ALL tools to be *ENSURED INSTALLED* by mason-tool-installer
      local tools_to_ensure_installed = {
        -- === LSPs ===
        'lua-language-server',
        'jdtls',
        npm 'pyright',
        zip 'clangd',
        'rust-analyzer',
        npm 'eslint-lsp',
        zip 'kotlin-language-server',
        'texlab',
        'taplo', -- TOML LSP
        'marksman', -- Markdown LSP
        npm 'typescript-language-server', -- JS/TS LSP

        -- === Formatters (Must match coding/format.lua) ===
        -- 'stylua', -- Lua
        pip 'clang-format', -- C/C++
        pip 'cmakelang', -- CMake
        pip 'black', -- Python
        pip 'isort', -- Python
        'google-java-format', -- Java
        pip 'xmlformatter', -- XML
        npm 'sql-formatter', -- SQL
        npm 'prettier', -- JS/TS/JSON/YAML/HTML/CSS
        npm 'prettierd', -- Prettier Daemon (Faster)
        npm 'eslint_d', -- JS/TS Linter
        'buf', -- Protobuf
        'ktfmt', -- Kotlin
        -- 'rustfmt', -- Rust
        -- 'gofumpt', -- Go (stricter gofmt)
        -- 'goimports', -- Go
        'cbfmt', -- Markdown code block formatter
        'latexindent', -- LaTeX
        npm 'bibtex-tidy', -- BibTeX

        -- === Linters (Must match coding/lint.lua) ===
        'hadolint',
        npm 'jsonlint',
        pip 'codespell',

        -- === Debug Adapters (Must match lsp/dap-core.lua) ===
        pip 'debugpy',
        zip 'codelldb',
        zip 'bash-debug-adapter',
      }
            --
      -- Setup Mason. A fresh pip in each Python tool's venv: Ubuntu 20.04's pip 20.0
      -- can't read today's wheel tags.
      require('mason').setup { pip = { upgrade_pip = true } }

      -- (Keep your mason-tool-installer setup as is)
      require('mason-tool-installer').setup {
        ensure_installed = tools_to_ensure_installed,
        auto_update = true,
        run_on_start = true,
      }

      -- Setup mason-lspconfig
      -- NOTE: In Nvim 0.11+, we strictly use this for ensuring installation mapping.
      -- We DO NOT use 'handlers' here anymore because that triggers the deprecated API.
      -- It enables every installed server, but these run on java, a hand install off
      -- arch: without it they'd crash on every kotlin buffer.
      local needs_java = vim.fn.executable 'java' == 0 and { 'kotlin_language_server' } or {}
      -- ltex (grammar) stays off where mason still has it: text gets spelling only
      -- (autocmds.lua).
      require('mason-lspconfig').setup {
        automatic_enable = { exclude = vim.list_extend({ 'ltex' }, needs_java) },
      }

      -- Manually configure and enable servers using the new Nvim 0.11 API
      for server_name, server_config in pairs(lsp_servers) do
        -- Skip jdtls (if you handle it separately with nvim-jdtls)
        if server_name ~= 'jdtls' and not vim.tbl_contains(needs_java, server_name) then
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
