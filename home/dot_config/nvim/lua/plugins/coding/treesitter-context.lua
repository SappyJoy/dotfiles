return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      enable = true,
      max_lines = 3, -- Keep it compact
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to show for a single context
      trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded
      mode = 'cursor', -- Line used to calculate context. Can be 'cursor' or 'topline'
    },
    keys = {
      {
        '[t',
        function()
          require('treesitter-context').go_to_context(vim.v.count1)
        end,
        desc = 'Jump to Context Top',
      },
    },
  },
}
