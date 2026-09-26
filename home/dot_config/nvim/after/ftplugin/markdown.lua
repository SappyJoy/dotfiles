require("quarto").activate()

--
-- -- markdown link text objects for i and a
-- vim.keymap.set({ "o", "x" }, "il", "<cmd>lua require('various-textobjs').mdlink('inner')<CR>", { buffer = true })
-- vim.keymap.set({ "o", "x" }, "al", "<cmd>lua require('various-textobjs').mdlink('outer')<CR>", { buffer = true })
vim.b.slime_cell_delimiter = '```'

-- wrap text, but by word no character
-- indent the wrappped line
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.conceallevel = 2

-- Jupytext/Molten Compatibility:
-- Check if the markdown file is a Jupytext notebook by looking for "jupyter:" in the frontmatter.
local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
if first_line and first_line == "---" then
  local is_notebook = false
  for i = 1, 10 do
    local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1] or ""
    if line:match("^jupyter:") then
      is_notebook = true
      break
    end
    if line == "---" then
      break
    end
  end

  if is_notebook then
    -- If it's a notebook, disable render-markdown's code block rendering
    -- to allow molten-nvim to display its virtual text output correctly.
    vim.b.render_markdown_code_enabled = false
  end
end

-- Auto-close YAML frontmatter fold in Markdown files (Deferred)
local buf = vim.api.nvim_get_current_buf()

-- Standard Treesitter fold setup for the buffer
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt_local.foldlevel = 99 -- Start open to allow selective closing

-- Defer the fold closing with an explicit delay
vim.defer_fn(function()
  -- Ensure buffer is still valid
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  vim.api.nvim_buf_call(buf, function()
    -- Check if first line looks like frontmatter
    local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    if first_line and first_line:match '^%-%-%-$' then
      -- Verify a fold exists at line 1
      if vim.fn.foldlevel(1) > 0 then
        pcall(vim.cmd, '1foldclose')
        pcall(vim.cmd, 'normal! Hzz')
      end
    end
  end)
end, 100)
