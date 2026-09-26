return {
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'onsails/lspkind.nvim',
      {
        'petertriho/cmp-git',
        opts = {},
      },
      {
        'zbirenbaum/copilot-cmp',
        config = function()
          require('copilot_cmp').setup()
        end,
      },
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      local lspkind = require 'lspkind'

      vim.defer_fn(function()
        cmp.setup {
          enabled = function()
            -- Disable in Telescope
            if vim.bo.filetype == 'TelescopePrompt' then
              return false
            end

            -- Disable in Oil
            local bufnr = vim.api.nvim_get_current_buf()
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if bufname:match 'oil://' then
              return false
            end
            pcall(require('langmapper').put_back_keymap)
            return true
          end,
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          completion = {
            completeopt = 'menu,menuone,noinsert',
          },
          mapping = cmp.mapping.preset.insert {
            ['<C-y>'] = cmp.mapping.confirm { select = true },
            -- Accept currently selected item. If none selected, `select = false` allows <CR> to insert newline.
            ['<CR>'] = cmp.mapping.confirm { select = false },
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
            ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
            ['<C-u>'] = cmp.mapping.scroll_docs(-4),
            ['<C-d>'] = cmp.mapping.scroll_docs(4),
            ['<C-l>'] = cmp.mapping(function(fallback)
              if luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<C-h>'] = cmp.mapping(function(fallback)
              if luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          },
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
          sources = cmp.config.sources {
            { name = 'nvim_lsp', priority = 10 },
            { name = 'luasnip', priority = 9 },
            { name = 'copilot', priority = 8 },
            { name = 'codeium', priority = 7 },
            { name = 'buffer', priority = 6 },
            { name = 'path', priority = 5 },
            { name = 'git', priority = 4 },
          },
          sorting = {
            priority_weight = 2,
            comparators = {
              require('copilot_cmp.comparators').prioritize,
              cmp.config.compare.offset,
              cmp.config.compare.exact,
              cmp.config.compare.score,
              cmp.config.compare.recently_used,
              cmp.config.compare.kind,
              cmp.config.compare.sort_text,
              cmp.config.compare.length,
              cmp.config.compare.order,
            },
          },
          formatting = {
            format = lspkind.cmp_format {
              mode = 'symbol_text',
              maxwidth = 50,
              ellipsis_char = '...',
              symbol_map = {
                Text = '󰉿',
                Method = '󰆧',
                Function = '󰊕',
                Constructor = '',
                Field = '󰜢',
                Variable = '󰀫',
                Class = '󰠱',
                Interface = '',
                Module = '',
                Property = '󰜢',
                Unit = '󰑭',
                Value = '󰎠',
                Enum = '',
                Keyword = '󰌋',
                Snippet = '',
                Color = '󰏘',
                File = '󰈙',
                Reference = '󰈇',
                Folder = '󰉋',
                EnumMember = '',
                Constant = '󰏿',
                Struct = '󰙅',
                Event = '',
                Operator = '󰆕',
                TypeParameter = '󰊄',
                Copilot = '',
                Codeium = '',
              },
            },
          },
        }
      end, 100)

      cmp.event:on('menu_closed', function()
        pcall(function()
          local langmapper = require 'langmapper'
          langmapper._hack_keymap()
          langmapper.hack_get_keymap()
        end)
      end)
    end,
  },
}
