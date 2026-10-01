-- The picker: telescope, for files, grep, buffers, help, keymaps and (later) LSP.
local function builtin(name, opts)
  return function()
    require('telescope.builtin')[name](opts)
  end
end

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>s', group = 'search' } } } },
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'nvim-telescope/telescope-ui-select.nvim',
    },
    keys = {
      { '<leader>sf', builtin 'find_files', desc = 'Files' },
      { '<leader>sg', builtin 'live_grep', desc = 'Grep' },
      { '<leader>sw', builtin 'grep_string', desc = 'Word under cursor' },
      { '<leader>s.', builtin 'oldfiles', desc = 'Recent files' },
      { '<leader>sr', builtin 'resume', desc = 'Resume last search' },
      { '<leader>sh', builtin 'help_tags', desc = 'Help' },
      { '<leader>sk', builtin 'keymaps', desc = 'Keymaps' },
      { '<leader>sd', builtin 'diagnostics', desc = 'Diagnostics' },
      { '<leader>sl', builtin 'git_status', desc = 'Git changes' },
      {
        '<leader>s/',
        builtin('live_grep', { grep_open_files = true, prompt_title = 'Grep open files' }),
        desc = 'Grep open files',
      },
      { '<leader>sn', builtin('find_files', { cwd = vim.fn.stdpath 'config' }), desc = 'nvim config' },
      {
        '<leader>sc',
        function()
          local dir = vim.bo.filetype == 'oil' and require('oil').get_current_dir() or vim.fn.expand '%:p:h'
          require('telescope.builtin').live_grep {
            cwd = dir,
            prompt_title = 'Grep in ' .. vim.fn.fnamemodify(dir, ':~'),
          }
        end,
        desc = "Grep in the file's dir",
      },
      { '<leader><leader>', builtin('buffers', { sort_mru = true }), desc = 'Buffers' },
      { '<leader>/', builtin 'current_buffer_fuzzy_find', desc = 'Search in buffer' },
    },
    init = function()
      -- vim.ui.select (code actions, spelling, …) through telescope, loaded on first use
      vim.ui.select = function(...)
        require('telescope').load_extension 'ui-select'
        return vim.ui.select(...)
      end
    end,
    config = function()
      local actions = require 'telescope.actions'
      -- Ctrl+Q: all results to the quickfix list (for <leader>xr, :cdo), shown in
      -- trouble only, not also in vim's own quickfix window
      local function to_list(bufnr)
        actions.send_to_qflist(bufnr)
        vim.cmd 'Trouble qflist open'
      end
      require('telescope').setup {
        defaults = {
          mappings = {
            i = { ['<C-y>'] = actions.select_default, ['<C-q>'] = to_list },
            n = { ['<C-y>'] = actions.select_default, ['<C-q>'] = to_list },
          },
          layout_config = {
            horizontal = { prompt_position = 'bottom', preview_width = 0.5 },
            width = 0.87,
            height = 0.8,
            preview_cutoff = 120,
          },
        },
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      require('telescope').load_extension 'fzf'
    end,
  },
}
