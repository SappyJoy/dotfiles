return {
  {
    'GeorgesAlkhouri/nvim-aider',
    cmd = { 'Aider', 'AiderOpen' },
    dependencies = {
      { 'folke/snacks.nvim', version = '>=2.24.0' },
    },
    keys = {
      { '<leader>a/', '<cmd>Aider toggle<cr>', desc = 'Toggle Aider' },
      { '<leader>as', '<cmd>Aider send<cr>', desc = 'Send to Aider', mode = { 'n', 'v' } },
      { '<leader>ac', '<cmd>Aider command<cr>', desc = 'Aider Commands' },
      { '<leader>ab', '<cmd>Aider buffer<cr>', desc = 'Send Buffer' },
      { '<leader>a+', '<cmd>Aider add<cr>', desc = 'Add File' },
      { '<leader>a-', '<cmd>Aider drop<cr>', desc = 'Drop File' },
      { '<leader>ar', '<cmd>Aider add readonly<cr>', desc = 'Add Read-Only' },
      { '<leader>aR', '<cmd>Aider reset<cr>', desc = 'Reset Session' },
    },
    opts = {
      aider_cmd = 'aider',
      args = {
        '--no-auto-commits',
        '--pretty',
      },
      auto_reload = true,
      config = {
        os = { editPreset = 'nvim-remote' },
        gui = { nerdFontsVersion = '3' },
      },
      win = {
        wo = { winbar = 'Aider' },
        style = 'nvim_aider',
        position = 'right',
      },
    },
    config = function(_, opts)
      local aider = require 'nvim_aider'

      -- 1. Define Palettes
      local ayu_light = {
        user_input_color = '#86B300', -- ayu string
        tool_output_color = '#399EE6', -- ayu entity
        tool_error_color = '#E65050', -- ayu error
        tool_warning_color = '#FA8D3E', -- ayu warning
        assistant_output_color = '#A37ACC', -- ayu constant
        completion_menu_color = '#5C6166', -- ayu fg
        completion_menu_bg_color = '#F3F4F5', -- ayu panel_bg
        completion_menu_current_color = '#5C6166', -- ayu fg
        completion_menu_current_bg_color = '#D3E1F5', -- ayu selection_bg
      }

      local ayu_mirage = {
        user_input_color = '#B8E673', -- ayu mirage green
        tool_output_color = '#73D0FF', -- ayu mirage blue
        tool_error_color = '#FF3333', -- ayu mirage red
        tool_warning_color = '#FFC94A', -- ayu mirage yellow
        assistant_output_color = '#D4BFFF', -- ayu mirage purple
        completion_menu_color = '#CBCCC6', -- ayu mirage fg
        completion_menu_bg_color = '#232834', -- ayu mirage panel_bg
        completion_menu_current_color = '#CBCCC6',
        completion_menu_current_bg_color = '#33415E', -- ayu mirage selection_bg
      }

      -- 2. Setup Function
      local function setup_aider()
        local palette = vim.o.background == 'light' and ayu_light or ayu_mirage
        local new_opts = vim.tbl_deep_extend('force', opts, { theme = palette })
        aider.setup(new_opts)
      end

      -- 3. Initial Setup
      setup_aider()

      -- 4. Listen for Theme Changes
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
          setup_aider()
        end,
      })
    end,
  },
}
