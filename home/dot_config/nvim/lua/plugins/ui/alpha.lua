-- lua/plugins/alpha.lua
return {
  'goolord/alpha-nvim',
  enabled = false,
  event = 'VimEnter',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'folke/zen-mode.nvim',
    'epwalsh/obsidian.nvim',
    'folke/persistence.nvim',
  },
  keys = {
    { '<leader>hh', '<Cmd>Alpha<CR>', desc = 'Home' },
  },
  opts = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'

    -- Icons setup
    local use_nerd_fonts = vim.g.have_nerd_font
    local icons = {
      find_files = use_nerd_fonts and ' ' or 'F ',
      notes = use_nerd_fonts and '󰠮 ' or 'N ',
      zen = use_nerd_fonts and '󰒡 ' or 'Z ',
      recent_files = use_nerd_fonts and ' ' or 'R ',
      sessions = use_nerd_fonts and '󱂬 ' or 'S ',
      find_text = use_nerd_fonts and '󰍉 ' or 'G ',
      new_file = use_nerd_fonts and ' ' or 'E ',
      quit = use_nerd_fonts and '󰅚 ' or 'Q ',
      lazy = use_nerd_fonts and '󰒲  ' or 'L ',
    }

    local kitty_art = [[
                     ▄▀░░▌
                   ▄▀▐░░░▌
                ▄▀▀▒▐▒░░░▌
     ▄▀▀▄   ▄▄▀▀▒▒▒▒▌▒▒░░▌
    ▐▒░░░▀▄▀▒▒▒▒▒▒▒▒▒▒▒▒▒█
    ▌▒░░░░▒▀▄▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄
    ▐▒░░░░░▒▒▒▒▒▒▒▒▒▌▒▐▒▒▒▒▒▀▄
    ▌▀▄░░▒▒▒▒▒▒▒▒▐▒▒▒▌▒▌▒▄▄▒▒▐
   ▌▌▒▒▀▒▒▒▒▒▒▒▒▒▒▐▒▒▒▒▒█▄█▌▒▒▌
 ▄▀▒▐▒▒▒▒▒▒▒▒▒▒▒▄▀█▌▒▒▒▒▒▀▀▒▒▐░░░▄
▀▒▒▒▒▌▒▒▒▒▒▒▒▄▒▐███▌▄▒▒▒▒▒▒▒▄▀▀▀▀
▒▒▒▒▒▐▒▒▒▒▒▄▀▒▒▒▀▀▀▒▒▒▒▄█▀░░▒▌▀▀▄▄
▒▒▒▒▒▒█▒▄▄▀▒▒▒▒▒▒▒▒▒▒▒░░▐▒▀▄▀▄░░░░▀
▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▄▒▒▒▒▄▀▒▒▒▌░░▀▄
▒▒▒▒▒▒▒▒▀▄▒▒▒▒▒▒▒▒▀▀▀▀▒▒▒▄▀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

████████╗██╗   ██╗██████╗ ███████╗██╗    ██╗██████╗ ██╗████████╗███████╗██████╗
╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝██╔══██╗
   ██║    ╚████╔╝ ██████╔╝█████╗  ██║ █╗ ██║██████╔╝██║   ██║   █████╗  ██████╔╝
   ██║     ╚██╔╝  ██╔═══╝ ██╔══╝  ██║███╗██║██╔══██╗██║   ██║   ██╔══╝  ██╔══██╗
   ██║      ██║   ██║     ███████╗╚███╔███╔╝██║  ██║██║   ██║   ███████╗██║  ██║
   ╚═╝      ╚═╝   ╚═╝     ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
    ]]

    local footer_quote = '"Уже привык и даже улыбаюсь." - А.П. Чехов'

    dashboard.section.header.val = vim.split(kitty_art, '\n')
    dashboard.section.header.opts.hl = 'AlphaHeader'
    dashboard.section.header.opts.align = 'center'

    dashboard.section.buttons.val = {
      dashboard.button('f', icons.find_files .. ' Find file', '<cmd>Telescope find_files<CR>'),
      dashboard.button('o', icons.notes .. ' Obsidian Notes', '<cmd>ObsidianQuickSwitch<CR>'),
      dashboard.button('z', icons.zen .. ' Zen Mode', '<cmd>ZenMode<CR>'),
      dashboard.button('n', icons.new_file .. ' New file', '<cmd>ene <bar> startinsert<CR>'),
      dashboard.button('r', icons.recent_files .. ' Recent files', '<cmd>Telescope oldfiles<CR>'),
      dashboard.button('g', icons.find_text .. ' Find text', '<cmd>Telescope live_grep<CR>'),
      dashboard.button('s', icons.sessions .. ' Sessions', "<cmd>lua require('persistence').select()<CR>"),
      dashboard.button('l', icons.lazy .. ' Lazy', '<cmd>Lazy<CR>'),
      dashboard.button('q', icons.quit .. ' Quit', '<cmd>qa<CR>'),
    }
    for _, button in ipairs(dashboard.section.buttons.val) do
      button.opts.hl = 'AlphaButtons'
      button.opts.hl_shortcut = 'AlphaShortcut'
    end
    dashboard.section.buttons.opts.align = 'center'

    dashboard.section.footer.val = { footer_quote }
    dashboard.section.footer.opts.hl = 'AlphaFooter'
    dashboard.section.footer.opts.align = 'center'

    local padding_below_header = 2
    local padding_below_buttons = 0
    local padding_below_footer = 1

    local header_height = #dashboard.section.header.val
    local button_height = #dashboard.section.buttons.val
    local footer_height = #dashboard.section.footer.val

    local total_content_height = header_height + padding_below_header + button_height + padding_below_buttons + footer_height + padding_below_footer

    local window_height = vim.api.nvim_win_get_height(0)
    if window_height <= 0 then
      window_height = vim.o.lines
    end

    local top_padding = math.max(1, math.floor((window_height - total_content_height) / 2))

    dashboard.opts.layout = {
      { type = 'padding', val = top_padding },
      dashboard.section.header,
      { type = 'padding', val = padding_below_header },
      dashboard.section.buttons,
      { type = 'padding', val = padding_below_buttons },
      dashboard.section.footer,
      { type = 'padding', val = padding_below_footer },
    }

    return dashboard
  end,

  config = function(_, dashboard)
    if vim.o.filetype == 'lazy' then
      vim.cmd.close()
      vim.api.nvim_create_autocmd('User', {
        once = true,
        pattern = 'AlphaReady',
        callback = function()
          require('lazy').show()
        end,
      })
    end

    require('alpha').setup(dashboard.opts)
  end,
}
