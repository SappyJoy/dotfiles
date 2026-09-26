return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' }, -- Lazy load only for Java files
  },
  {
    'ariedov/android-nvim',
    ft = { 'java', 'kotlin', 'xml' }, -- Load for Android-related filetypes
    config = function()
      -- Specify android sdk directory if needed
      -- vim.g.android_sdk = '~/Android/Sdk'
      require('android-nvim').setup()
    end,
  },
}
