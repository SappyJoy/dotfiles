-- Small tools: translation (Google's, over the network) and colors shown behind their
-- codes (#e6b450, rgb(…)).

-- <leader>T: the line or the selection, Russian to English, anything else to Russian
local function translate()
  local mode = vim.fn.mode()
  local text, range = vim.fn.getline '.', ''
  if mode:find '[vV\22]' then
    text = table.concat(vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode }), ' ')
    vim.cmd 'normal! \27' -- leave Visual: the command reads the '< '> marks
    range = "'<,'>"
  end
  vim.cmd(range .. 'Translate ' .. (text:find '[\208\209][\128-\191]' and 'EN' or 'RU'))
end

return {
  {
    'uga-rosa/translate.nvim',
    cmd = 'Translate',
    keys = { { '<leader>T', translate, mode = { 'n', 'x' }, desc = 'Translate (ru ↔ en)' } },
  },
  {
    'catgoose/nvim-colorizer.lua',
    event = 'VeryLazy',
    opts = {
      filetypes = { '*' },
      lazy_load = true,
      -- hex codes and rgb()/hsl(); color names ("red") stay plain words
      options = { parsers = { css_fn = true, names = { enable = false } } },
    },
    config = function(_, opts)
      local colorizer = require 'colorizer'
      colorizer.setup(opts)
      -- it loads after the first screen: the files already shown get it too
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == '' then
          colorizer.attach_to_buffer(buf)
        end
      end
    end,
  },
}
