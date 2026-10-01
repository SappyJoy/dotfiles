-- Ayu, light or mirage, in step with the desktop: theme-switcher writes the mode to
-- ~/.config/nvim/.theme_state and switches running nvims; a colorscheme picked here
-- switches the desktop.
local state_file = vim.fn.expand '~/.config/nvim/.theme_state'

local function overrides()
  local colors = require 'ayu.colors' -- the palette of the variant just loaded
  local hl = vim.api.nvim_set_hl
  hl(0, 'LineNr', { fg = colors.guide_active })
  hl(0, 'Comment', { fg = colors.comment }) -- no italics
  hl(0, 'GitSignsAdd', { fg = colors.vcs_added })
  hl(0, 'GitSignsChange', { fg = colors.vcs_modified })
  hl(0, 'GitSignsDelete', { fg = colors.vcs_removed })
  hl(0, 'GitSignsCurrentLineBlame', { fg = colors.comment })
end

return {
  'Shatur/neovim-ayu',
  lazy = false,
  priority = 1000,
  config = function()
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = 'ayu*',
      callback = function(args)
        overrides()
        local mode = args.match == 'ayu-light' and 'light' or 'dark'
        local current = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file)[1]
        -- not from a headless nvim (tests, installs): it would switch the desktop
        local ui = #vim.api.nvim_list_uis() > 0
        if ui and mode ~= current and vim.fn.executable 'theme-switcher' == 1 then
          vim.system({ 'theme-switcher', mode }, { detach = true })
        end
      end,
    })
    local dark = vim.fn.filereadable(state_file) == 1 and vim.fn.readfile(state_file)[1] == 'dark'
    vim.cmd.colorscheme(dark and 'ayu-mirage' or 'ayu-light')
  end,
}
