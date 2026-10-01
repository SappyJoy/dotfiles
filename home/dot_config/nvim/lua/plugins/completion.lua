-- Completion: blink.cmp, keys as before. Ctrl+Y takes the first item (or the
-- selected one), Enter only an item picked with Ctrl+N/Ctrl+P, Ctrl+Space opens
-- the menu, Ctrl+E closes it. Snippets come as items: nothing to memorize.
-- On the : line it completes commands as you type (:cd → cdo, cfdo, …).
local text = require('ui.prose').filetypes

return {
  'saghen/blink.cmp',
  version = '1.*', -- a release: its fuzzy matcher comes prebuilt
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = { 'rafamadriz/friendly-snippets' },
  opts = {
    keymap = {
      preset = 'default',
      ['<C-y>'] = { 'select_and_accept' },
      ['<CR>'] = { 'accept', 'fallback' },
    },
    completion = {
      list = { selection = { preselect = false, auto_insert = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
      -- in prose a menu on every word is friction: there Ctrl+Space opens it
      menu = {
        auto_show = function()
          return not text[vim.bo.filetype]
        end,
      },
    },
    signature = { enabled = true },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    cmdline = {
      keymap = { preset = 'cmdline' },
      completion = { menu = { auto_show = true } },
    },
  },
}
