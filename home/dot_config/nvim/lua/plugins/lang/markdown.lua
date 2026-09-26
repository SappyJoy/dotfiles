return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto', 'norg', 'Avante' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      file_types = { 'markdown', 'quarto', 'norg', 'Avante' },
      -- Enable rendering in all modes (including Insert) so cells don't disappear
      render_modes = { 'n', 'c', 't', 'i', 'v', 'V', '\22' },

      -- Turn off latex rendering to avoid needing 'latex2text' executable
      latex = { enabled = false },

      -- Configure code block appearance to look like "cells"
      code = {
        sign = false,
        width = 'full', -- Stretch to window width
        right_pad = 1,
        -- conceal_delimiters = false,
        border = 'none',
      },

      -- Adjust header appearance
      heading = {
        sign = false,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },
      },

      -- Enable Obsidian compatibility
      checkbox = {
        enabled = true,
        custom = {
          todo = { raw = '[-]', rendered = '󰄱 ', highlight = 'RenderMarkdownTodo' },
          done = { raw = '[x]', rendered = '󰄲 ', highlight = 'RenderMarkdownDone' },
        },
      },
    },
  },
}
