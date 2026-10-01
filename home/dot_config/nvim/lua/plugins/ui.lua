-- UI from snacks: the dashboard (the portrait, TYPEWRITER, Chekhov), notifications,
-- indent guides. Other modules add their parts of snacks (explorer, lazygit, images).
return {
  { 'nvim-tree/nvim-web-devicons', lazy = true }, -- file icons (oil, telescope, trouble)
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    opts = {
      dashboard = {
        preset = {
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
          keys = {
            { icon = ' ', key = 'f', desc = 'Find file', action = ':Telescope find_files' },
            { icon = ' ', key = 'n', desc = 'New file', action = ':ene | startinsert' },
            { icon = ' ', key = 'g', desc = 'Grep', action = ':Telescope live_grep' },
            { icon = ' ', key = 'r', desc = 'Recent files', action = ':Telescope oldfiles' },
            {
              icon = ' ',
              key = 'c',
              desc = 'Config',
              action = ':Telescope find_files cwd=' .. vim.fn.stdpath 'config',
            },
            { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
        },
        sections = {
          { section = 'header', align = 'left' },
          { section = 'keys', gap = 1, padding = 1 },
          { section = 'startup' },
          {
            text = {
              '"Уже привык и даже улыбаюсь." - А.П. Чехов',
              hl = 'Comment',
            },
            align = 'center',
            padding = 1,
          },
        },
      },
      -- headless (tests, installs): notifications stay plain messages
      notifier = { enabled = #vim.api.nvim_list_uis() > 0 },
      indent = { enabled = true },
    },
  },
}
