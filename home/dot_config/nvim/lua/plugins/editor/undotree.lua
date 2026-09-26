return {
  {
    'mbbill/undotree',
    keys = {
      {
        '<leader>u',
        -- Chain commands: Toggle the undotree window AND focus it immediately
        '<cmd>UndotreeToggle<CR><cmd>UndotreeFocus<CR>',
        desc = '[U]ndo Tree Toggle & Focus',
        silent = true,
        noremap = true, -- Good practice for custom mappings
      },
    },
    cmd = { 'UndotreeToggle', 'UndotreeFocus' }, -- Lazy load on command
  },
}
