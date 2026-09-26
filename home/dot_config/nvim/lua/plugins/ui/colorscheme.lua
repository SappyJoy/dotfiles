return {
  {
    'Shatur/neovim-ayu',
    priority = 1000,
    config = function()
      local function apply_overrides()
        local ok, colors = pcall(require, 'ayu.colors')
        if not ok then return end
        
        -- Determine if we need mirage palette
        local is_mirage = vim.g.colors_name == 'ayu-mirage'
        colors.generate(is_mirage)

        local set_hl = vim.api.nvim_set_hl

        -- UI Highlights (Dynamic based on palette)
        set_hl(0, 'GitSignsCurrentLineBlame', { fg = colors.comment })
        set_hl(0, 'GitSignsAdd', { fg = colors.vcs_added })
        set_hl(0, 'GitSignsChange', { fg = colors.vcs_modified })
        set_hl(0, 'GitSignsDelete', { fg = colors.vcs_removed })
        set_hl(0, 'LineNr', { fg = colors.guide_active })
        
        -- REMOVED hardcoded Visual and CmpNormal. 
        -- The theme handles these correctly for Dark/Light modes.
        
        -- Dashboard Highlights
        set_hl(0, 'AlphaHeader', { fg = colors.accent })
        set_hl(0, 'AlphaButtons', { link = 'String' })
        set_hl(0, 'AlphaShortcut', { link = 'Type' })
        set_hl(0, 'AlphaFooter', { link = 'Comment' })

        -- C++ Fixes
        set_hl(0, '@lsp.type.comment.cpp', {})

        vim.cmd.hi 'Comment gui=none'
      end

      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function(args)
          local theme = args.match
          local new_mode = 'dark'
          if theme:match 'light' or theme:match 'day' or theme:match 'latte' or theme:match 'dawn' then
            new_mode = 'light'
          end

          -- Sync System Theme
          local state_file = vim.fn.expand '~/.config/nvim/.theme_state'
          local current_mode = nil
          if vim.fn.filereadable(state_file) == 1 then
            current_mode = vim.fn.readfile(state_file)[1]
          end

          if new_mode ~= current_mode then
            local script = vim.fn.expand '~/.local/bin/theme-switcher'
            if vim.fn.filereadable(script) == 1 then
              vim.system({ script, new_mode }, { detach = true })
            end
          end

          -- Re-apply highlights for the new theme
          apply_overrides()
        end,
      })

      -- Load Initial Theme
      local state_file = vim.fn.expand '~/.config/nvim/.theme_state'
      local theme_to_load = 'ayu-light'
      if vim.fn.filereadable(state_file) == 1 then
        local state = vim.fn.readfile(state_file)[1]
        if state == 'dark' then
          theme_to_load = 'ayu-mirage'
        end
      end

      vim.cmd.colorscheme(theme_to_load)
    end,
  },

  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  { 'folke/tokyonight.nvim', priority = 1000 },
  { 'morhetz/gruvbox', priority = 1000 },
  { 'EdenEast/nightfox.nvim', priority = 1000 },
  { 'sainnhe/gruvbox-material', priority = 1000 },
  { 'sainnhe/everforest', priority = 1000 },
  { 'nyoom-engineering/oxocarbon.nvim', priority = 1000 },
  { 'ribru17/bamboo.nvim', priority = 1000 },
  { 'rose-pine/neovim', priority = 1000 },
  { 'navarasu/onedark.nvim', priority = 1000 },
  { 'miikanissi/modus-themes.nvim', priority = 1000 },
  { 'binhtran432k/dracula.nvim', priority = 1000 },
  { 'mofiqul/vscode.nvim', priority = 1000 },
  { 'rmehri01/onenord.nvim', priority = 1000 },
  { 'cocopon/iceberg.vim', priority = 1000 },
  { 'sainnhe/edge', priority = 1000 },
  { 'sonph/onehalf', priority = 1000 },
  { 'rakr/vim-one', priority = 1000 },
  { 'ntbbloodbath/doom-one.nvim', priority = 1000 },
  { 'p00f/alabaster.nvim', priority = 1000 },
  { 'chriskempson/vim-tomorrow-theme', priority = 1000 },
  { 'olimorris/onedarkpro.nvim', priority = 1000 },
  { 'nlknguyen/papercolor-theme', priority = 1000 },
  { 'hzchirs/vim-material', priority = 1000 },
  { 'soft-aesthetic/soft-era-vim', priority = 1000 },

  -- vim.cmd.colorscheme 'ayu-light',
}
