--                      ▄▀░░▌
--                    ▄▀▐░░░▌
--                 ▄▀▀▒▐▒░░░▌
--      ▄▀▀▄   ▄▄▀▀▒▒▒▒▌▒▒░░▌
--     ▐▒░░░▀▄▀▒▒▒▒▒▒▒▒▒▒▒▒▒█
--     ▌▒░░░░▒▀▄▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄
--     ▐▒░░░░░▒▒▒▒▒▒▒▒▒▌▒▐▒▒▒▒▒▀▄
--     ▌▀▄░░▒▒▒▒▒▒▒▒▐▒▒▒▌▒▌▒▄▄▒▒▐
--    ▌▌▒▒▀▒▒▒▒▒▒▒▒▒▒▐▒▒▒▒▒█▄█▌▒▒▌
--  ▄▀▒▐▒▒▒▒▒▒▒▒▒▒▒▄▀█▌▒▒▒▒▒▀▀▒▒▐░░░▄
-- ▀▒▒▒▒▌▒▒▒▒▒▒▒▄▒▐███▌▄▒▒▒▒▒▒▒▄▀▀▀▀
-- ▒▒▒▒▒▐▒▒▒▒▒▄▀▒▒▒▀▀▀▒▒▒▒▄█▀░░▒▌▀▀▄▄
-- ▒▒▒▒▒▒█▒▄▄▀▒▒▒▒▒▒▒▒▒▒▒░░▐▒▀▄▀▄░░░░▀
-- ▒▒▒▒▒▒▒█▒▒▒▒▒▒▒▒▒▄▒▒▒▒▄▀▒▒▒▌░░▀▄
-- ▒▒▒▒▒▒▒▒▀▄▒▒▒▒▒▒▒▒▀▀▀▀▒▒▒▄▀

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      -- Replace Alpha with Snacks Dashboard
      dashboard = {
        enabled = true,
        preset = {
          -- Your custom ASCII Art
          header = [[
                           ▓▄█▒▄                      
                   ░▓▓▒░   ██████░▒▓░▄                
              ░ ░▒▓██░█░█ ▄████▓▓▒█▓█░░░              
               ▒▒▒██▒███░▒▒▒█░█████▓███▓▒             
             ▄▄██▒█░  ██▒▒██▓▓▓░░▒█░▓██   ░░░▄▄       
         ▄▒▄ ░██░▒█▒▓████▓▒▒▒░░▒░▒▓▓█░█▓█████▒█░░▒░   
        ▀███░░█░███▓▓███▓░░░░░░░▒▒░░▒▒████▓▓▒█▓▓██▒█  
      ▄   ████░▒░█▓▓█▓▓▒░▒▒░░▓██ ▓█▒▒▓█▓▓▒▓▓░░░█▓▓▒▀  
     ▄░▒█░▓██▓▓▓█████▓▓████████▄▓▓ ▒▒▒▒▓██▓▓▓█▓██▒▄   
     ▀█▒░▓░▒▓█▒░███▓▓▓███████▓░██▒▒░█████░░▒▓▓▓▒█▀▀   
         ██████████▀▀▓▀▓█████░▓██▓█████▓▓▒▓▓▒▓█       
       ▄▄█░▓▓▒▒▒   ▄   █░█████▒▒██░▓██▀ ▓▒▓▓▒▒▓██▓▓   
    ▄▄██▒▒▒░░░███ ███▄▄██▓▒█▓▒▒▒█▒▓▓▒   ▓▓▓▓██▒▒▓█▒▒▒ 
    █████░ ░▒████████▓▓█▓▒░▓█▓█▓▓░▒▒░▒ ░▒▒▒▒▓▓▒▓█▒░▒█▒
     ▀▒▒░░  ░▓█████░▒█▓████▒▓░░░░▒▒███▒▒▓▓█████▓█░████
           ░▒▒▓███▓▓▓▓▓▒▀▀█▒▒░▒▓▒  ░░▀░▒▓▓▒███░██▒▒█  
          ░▓▓▓▒░▒██▓▀█▄▄ ░██▒▓░▓  ▄█▀   ░▒▓▒█  ██▓▀   
            ░▒██▒     ▀█████▒▒░▒▄██             ▀     
                        ██▒███░▒░▀                    
                        █▒▒▒▒▒▒░█▓                    
                       ▄█▒▒▒▒▓▒░█                     
                       █▒▒░█░▒▓░░░                    
                      ▄█▓  ▀▓▓▓▒▓▓░░                  
                   ▄▄░▀       ▀▀▀▀░░░░░░▄             
                ▀▀▀▀                 ▀▀▀▀▀▀           
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

████████╗██╗   ██╗██████╗ ███████╗██╗    ██╗██████╗ ██╗████████╗███████╗██████╗
 ╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝██╔══██╗
    ██║    ╚████╔╝ ██████╔╝█████╗  ██║ █╗ ██║██████╔╝██║   ██║   █████╗  ██████╔╝
    ██║     ╚██╔╝  ██╔═══╝ ██╔══╝  ██║███╗██║██╔══██╗██║   ██║   ██╔══╝  ██╔══██╗
    ██║      ██║   ██║     ███████╗╚███╔███╔╝██║  ██║██║   ██║   ███████╗██║  ██║
    ╚═╝      ╚═╝   ╚═╝     ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
    ]],
          -- Overwrite the default keys to use Telescope
          keys = {
            { icon = ' ', key = 'f', desc = 'Find File', action = ':Telescope find_files' },
            { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
            { icon = ' ', key = 'g', desc = 'Grep Text', action = ':Telescope live_grep' },
            { icon = ' ', key = 'r', desc = 'Recent Files', action = ':Telescope oldfiles' },
            { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
            { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
        },
        sections = {
          { section = 'header', align = 'left' },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'startup' },
          {
            section = 'terminal',
            -- Quote using `echo` since we are in terminal section
            cmd = 'echo \'         "Уже привык и даже улыбаюсь." - А.П. Чехов\'',
            hl = 'Comment',
            padding = 1,
            align = 'center',
          },
        },
      },
      -- Enable nice notifications
      notifier = { enabled = true },
      -- Enable floating terminal
      terminal = { enabled = true },
      -- Enable fast buffer deletion
      bufdelete = { enabled = true },

      -- Enable git status in statusline (optional)
      git = { enabled = true },

      -- Better Indent Guides (Replaces indent-blankline)
      indent = { enabled = true },

      -- Current Scope Highlight (Replaces mini.indentscope)
      scope = { enabled = true },

      -- Word Usage Highlight (Replaces vim-illuminate)
      words = { enabled = true },

      -- Zen Mode Configuration
      zen = {
        toggles = {
          dim = false, -- Disable background dimming
        },
      },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
        scratch = {
          wo = { wrap = true, linebreak = true, colorcolumn = "" }, -- Wrap text without breaking words
        },
      },
      picker = {
        actions = {
          -- Custom action to add file to Aider
          aider_add = function(picker, item)
            local aider = require('nvim_aider').api
            if item and item.file then
              aider.add_file(item.file)
              -- vim.notify('Added to Aider: ' .. item.file, vim.log.levels.INFO) -- Aider typically notifies itself
            end
          end,
          -- Custom action to drop file from Aider
          aider_drop = function(picker, item)
            local aider = require('nvim_aider').api
            if item and item.file then
              aider.drop_file(item.file)
              -- vim.notify('Dropped from Aider: ' .. item.file, vim.log.levels.INFO)
            end
          end,
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ['+'] = 'aider_add',
                  ['-'] = 'aider_drop',
                },
              },
            },
          },
        },
      },
    },
    keys = {
      {
        '<leader>hh',
        function()
          Snacks.dashboard()
        end,
        desc = 'Home (Dashboard)',
      },

      -- Top Pickers & Explorer
      {
        '<leader><space>',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Buffers',
      },
      {
        '<leader>e',
        function()
          Snacks.explorer()
        end,
        desc = 'File Explorer',
      },

      -- Terminal
      {
        '<c-/>',
        function()
          Snacks.terminal()
        end,
        desc = 'Toggle Terminal',
      },
      {
        '<c-_>',
        function()
          Snacks.terminal()
        end,
        desc = 'which_key_ignore',
      },

      -- Buffer management
      {
        '<leader>bd',
        function()
          Snacks.bufdelete()
        end,
        desc = 'Delete Buffer',
      },

      -- Git
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gl',
        function()
          Snacks.lazygit.log()
        end,
        desc = 'Lazygit Log (File)',
      },
      {
        '<leader>gL',
        function()
          Snacks.lazygit.log_file()
        end,
        desc = 'Lazygit Log',
      },
      {
        '<leader>go',
        function()
          Snacks.gitbrowse()
        end,
        desc = 'Git Browse',
      },

      -- Other useful utils
      {
        '<leader>zm',
        function()
          Snacks.zen()
        end,
        desc = 'Toggle Zen Mode',
      },
      {
        '<leader>S',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle Scratch Pad',
      },
      {
        '<leader>sS',
        function()
          Snacks.picker.scratch()
        end,
        desc = 'Search Scratch Pads',
      },
      {
        '<leader>cR',
        function()
          Snacks.rename.rename_file()
        end,
        desc = 'Rename File',
      },
      {
        '<leader>nh',
        function()
          Snacks.notifier.show_history()

        end,
        desc = 'Notification History',
      },
    },
    init = function()
      -- Override Neovim's default notification handler
      vim.notify = require 'snacks.notifier'
    end,
  },
}
