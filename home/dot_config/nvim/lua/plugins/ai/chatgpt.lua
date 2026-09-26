return {
  {
    'jackMort/ChatGPT.nvim',
    enabled = false,
    event = 'VeryLazy',
    config = function()
      require('chatgpt').setup {
        api_key_cmd = 'pass show api/tokens/openai',
        openai_params = {
          model = 'o1-preview',
          frequency_penalty = 0,
          presence_penalty = 0,
          max_tokens = 4095,
          temperature = 0.2,
          top_p = 0.1,
          n = 1,
        },
      }
      local wk = require 'which-key'
      wk.add {
        {
          { '<leader>cg', '<cmd>ChatGPT<cr>', desc = 'Open ChatGPT' },
          { '<leader>cs', '<cmd>ChatGPTActAs<cr>', desc = 'ChatGPT Act As' },
        },
      }
      wk.add {
        {
          mode = { 'n', 'v' },
          { '<leader>cc', '<cmd>ChatGPTCompleteCode<cr>', desc = 'ChatGPT Complete Code' },
          { '<leader>ce', '<cmd>ChatGPTEditWithInstructions<cr>', desc = 'ChatGPT Edit With Instructions' },
          { '<leader>cr', group = 'ChatGPT Run' },
          { '<leader>crt', '<cmd>ChatGPTRun translate<cr>', desc = 'ChatGPT Run translate' },
          { '<leader>cra', '<cmd>ChatGPTRun add_tests<cr>', desc = 'ChatGPT Run add_tests' },
          { '<leader>crg', '<cmd>ChatGPTRun grammar_correction<cr>', desc = 'ChatGPT Run grammar_correction' },
          { '<leader>crs', '<cmd>ChatGPTRun summarize<cr>', desc = 'ChatGPT Run summarize' },
          { '<leader>crf', '<cmd>ChatGPTRun fix_bugs<cr>', desc = 'ChatGPT Run fix_bugs' },
          { '<leader>cre', '<cmd>ChatGPTRun explain_code<cr>', desc = 'ChatGPT Run explain_code' },
          { '<leader>crd', '<cmd>ChatGPTRun docstring<cr>', desc = 'ChatGPT Run docstring' },
          { '<leader>cro', '<cmd>ChatGPTRun optimize_code<cr>', desc = 'ChatGPT Run optimize_code' },
          { '<leader>crR', '<cmd>ChatGPTRun roxygen_edit<cr>', desc = 'ChatGPT Run roxygen_edit' },
          { '<leader>crc', '<cmd>ChatGPTRun complete_code<cr>', desc = 'ChatGPT Run complete_code' },
          { '<leader>crr', '<cmd>ChatGPTRun code_readability_analysis<cr>', desc = 'ChatGPT Run code_readability_analysis' },
          { '<leader>crk', '<cmd>ChatGPTRun keywords<cr>', desc = 'ChatGPT Run keywords' },
        },
      }
    end,
  },
}
