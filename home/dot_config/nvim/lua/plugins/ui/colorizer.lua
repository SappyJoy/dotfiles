return {
  {
    'norcalli/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' }, -- Can be lazy-loaded
    config = function()
      require('colorizer').setup {
        '*', -- Highlight all filetypes
        -- Or specify filetypes: { 'css', 'javascript', 'lua' }
        user_default_options = {
          RGB = true, -- Enable RGB display
          RRGGBB = true, -- Enable RRGGBB display
          names = false, -- Disable color names
          tailwind = true, -- Enable tailwindcss colors
          sass = { enable = true, parsers = { 'css' } }, -- Enable sass colors
          css = true, -- Enable নিঃসcss colors
          mode = 'background', -- Highlight the background
        },
      }
    end,
  },
}
