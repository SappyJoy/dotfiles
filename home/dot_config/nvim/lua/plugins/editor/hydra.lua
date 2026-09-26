-- Plugin for creating custom modal keymap layers (Hydras)
return {
  'nvimtools/hydra.nvim',
  event = 'VeryLazy',
  dependencies = {
    -- Nougat is used here specifically to refresh the statusline when entering/exiting a hydra
    'MunifTanjim/nougat.nvim',
  },
  config = function()
    local Hydra = require 'hydra'

    -- Global Hydra configuration options
    Hydra.setup {
      hint = {
        type = 'window',
        show_name = false,
        position = 'middle',
        float_opts = {
          border = vim.g.Border or 'rounded',
        },
      },
      on_enter = function()
        local nougat_ok, nougat = pcall(require, 'nougat')
        if nougat_ok then
          nougat.refresh_statusline(true)
        end
      end,
      on_exit = function()
        vim.schedule(function()
          local nougat_ok, nougat = pcall(require, 'nougat')
          if nougat_ok then
            nougat.refresh_statusline(true)
          end
        end)
      end,
    }

    -- === Windows & Tabs Hydra ===
    local window_hint = [[
 ^^^^^^^^^^^^     Move      ^^    Size   ^^   ^^     Split        ^^     Tabs
 ^^^^^^^^^^^^-------------  ^^-----------^^   ^^---------------  ^^---------------------
 ^ ^ _k_ ^ ^  ^ ^ ^ _K_ ^ ^    ^   _+_   ^      _s_: horizontally ^^ _c_: new tab
 _h_ ^ ^ _l_  ^ _H_ ^ ^ _L_    _<_     _>_      _v_: vertically   ^^ _d_: close tab
 ^ ^ _j_ ^ ^  ^ ^ ^ _J_ ^ ^    ^   _-_   ^      _q_: close window ^^ _n_: next tab
 focus^^^^^^  ^window^^^^  ^^^_=_: equalize ^   _z_: max height   ^^ _p_: prev tab
 ^ ^ ^ ^ ^ ^  ^ ^ ^ ^ ^ ^ ^  ^^ ^           ^   _x_: max width    ^^ _T_: window to new tab
 ^ ^ ^ ^ ^ ^  ^ ^ ^ ^ ^ ^ ^  ^^ ^           ^   _o_: remain only  ^^
]]

    Hydra {
      name = 'Windows & Tabs',
      hint = window_hint,
      config = {
        invoke_on_body = true,
        hint = {
          position = 'bottom',
          hide_on_load = false,
        },
        noremap = true,
      },
      mode = 'n',
      body = '<leader>w',
      heads = {
        { 'h', '<C-w>h', { desc = 'focus left' } },
        { 'j', '<C-w>j', { desc = 'focus down' } },
        { 'k', '<C-w>k', { desc = 'focus up' } },
        { 'l', '<C-w>l', { desc = 'focus right' } },
        { 'H', '<C-w>H', { desc = 'move left' } },
        { 'J', '<C-w>J', { desc = 'move down' } },
        { 'K', '<C-w>K', { desc = 'move up' } },
        { 'L', '<C-w>L', { desc = 'move right' } },
        { '<', '<C-w><', { desc = 'width -' } },
        { '-', '<C-w>-', { desc = 'height -' } },
        { '+', '<C-w>+', { desc = 'height +' } },
        { '>', '<C-w>>', { desc = 'width +' } },
        { '=', '<C-w>=', { desc = 'equalize' } },
        { 'z', '<c-w>_', { desc = 'maximize height' } },
        { 'x', '<c-w>|', { desc = 'maximize width' } },
        { 's', ':split<CR>', { desc = 'split horizontal' } },
        { 'v', ':vsplit<CR>', { desc = 'split vertical' } },
        { 'o', '<C-w>o', { exit = true, desc = 'remain only' } },
        { 'q', '<C-w>q', { desc = 'close window' } },
        { 'c', '<Cmd>tabnew<CR>', { desc = 'new tab' } },
        { 'd', '<Cmd>tabclose<CR>', { desc = 'close tab' } },
        { 'n', 'gt', { desc = 'next tab' } },
        { 'p', 'gT', { desc = 'prev tab' } },
        { 'T', '<C-w>T', { desc = 'window to new tab' } },
        { 'i', function() vim.cmd 'HydraHintToggle' end, { noremap = false, desc = 'toggle hint' } },
        { '<Esc>', nil, { exit = true, desc = false } },
        { 'w', nil, { exit = true, desc = false } },
      },
    }

    -- === Telescope Hydra ===
    local telescope_hint = [[
   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆         
    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦      
          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     _f_: files       _m_: marks
           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    _o_: old files   _g_: live grep
          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   _p_: projects    _/_: search in file
   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  _r_: resume      _u_: undotree
  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   _h_: vim help    _c_: commands
 ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  _k_: keymaps     _;_: commands history
 ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ _O_: options     _?_: search history
      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆    
       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃    
 ^
                 _<Enter>_: Telescope           _<Esc>_
]]

    Hydra {
      name = 'Telescope',
      hint = telescope_hint,
      config = {
        color = 'teal',
        invoke_on_body = true,
        hint = {
          position = 'middle',
          float_opts = {
            border = vim.g.Border or 'rounded',
          },
        },
      },
      mode = 'n',
      body = '<leader>ff',
      heads = {
        { 'f', '<cmd>Telescope find_files<cr>', { desc = 'files' } },
        { 'g', '<cmd>Telescope live_grep<cr>', { desc = 'live grep' } },
        { 'o', '<cmd>Telescope oldfiles<cr>', { desc = 'old files' } },
        { 'h', '<cmd>Telescope help_tags<cr>', { desc = 'vim help' } },
        { 'm', '<cmd>Telescope marks<cr>', { desc = 'marks' } },
        { 'k', '<cmd>Telescope keymaps<cr>', { desc = 'keymaps' } },
        { 'O', '<cmd>Telescope vim_options<cr>', { desc = 'options' } },
        { 'r', '<cmd>Telescope resume<cr>', { desc = 'resume' } },
        { 'p', '<cmd>Telescope project<cr>', { desc = 'projects' } }, -- Requires telescope-project extension
        { '/', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { desc = 'search in file' } },
        { '?', '<cmd>Telescope search_history<cr>', { desc = 'search history' } },
        { ';', '<cmd>Telescope command_history<cr>', { desc = 'command-line history' } },
        { 'c', '<cmd>Telescope commands<cr>', { desc = 'execute command' } },
        { 'u', '<cmd>silent! %foldopen! | UndotreeToggle<cr>', { desc = 'undotree' } },
        { '<Enter>', '<cmd>Telescope<cr>', { exit = true, desc = 'list all pickers' } },
        { '<Esc>', nil, { exit = true, nowait = true } },
      },
    }

    -- === Options Hydra ===
    local options_hint = [[

  _i_ %{list} invisible characters
  _s_ %{spell} spell
  _w_ %{wrap} wrap
  _l_ %{cul} cursor line
  _n_ %{nu} number
  _r_ %{rnu} relative number
  _c_ %{con} conceal
  _t_ %{twe} textwidth (%{tw})
  ^
       ^^^^                _<Esc>_
]]

    Hydra {
      name = 'Options',
      hint = options_hint,
      config = {
        color = 'amaranth',
        invoke_on_body = true,
        hint = {
          position = 'middle',
          float_opts = {
            title = ' Options Hydra ',
            title_pos = 'center',
          },
          funcs = {
            ['twe'] = function() return vim.o.textwidth == 0 and '[ ]' or '[x]' end,
            ['tw'] = function() return vim.o.textwidth end,
          },
        },
      },
      mode = { 'n' },
      body = '<leader>oh',
      heads = {
        { 'n', function() vim.o.number = not vim.o.number end },
        {
          'r',
          function()
            if vim.o.relativenumber then
              vim.o.relativenumber = false
            else
              vim.o.number = true
              vim.o.relativenumber = true
            end
          end,
        },
        { 'i', function() vim.o.list = not vim.o.list end },
        { 's', function() vim.o.spell = not vim.o.spell end },
        {
          'w',
          function()
            if not vim.o.wrap then
              vim.o.wrap = true
              vim.keymap.set('n', 'j', 'gj')
              vim.keymap.set('n', 'k', 'gk')
            else
              vim.o.wrap = false
              pcall(vim.keymap.del, 'n', 'j')
              pcall(vim.keymap.del, 'n', 'k')
            end
          end,
        },
        { 'l', function() vim.o.cursorline = not vim.o.cursorline end },
        { 'c', function() vim.o.conceallevel = vim.o.conceallevel == 0 and 1 or 0 end },
        { 't', function() vim.o.textwidth = vim.o.textwidth == 0 and 100 or 0 end },
        { '<Esc>', nil, { exit = true } },
      },
    }
  end,
}
