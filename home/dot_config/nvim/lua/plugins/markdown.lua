-- Markdown: rendered in place (render-markdown); images, LaTeX math and Mermaid drawn
-- in the note (snacks.image, kitty only); pasting a screenshot (img-clip); export
-- through pandoc. Keys in <leader>m (prose; ui/prose.lua has the typewriter).

-- A pasted image goes to the vault's attachment folder (Obsidian's app.json) inside
-- a vault, else to assets/ next to the file; the link is relative to the note. In
-- project notes (project_notes.lua), it goes to notes/assets/ and is embedded by name.
local function image_dir()
  local vault = vim.fs.root(0, '.obsidian')
  if vault then
    local ok, app = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(vault .. '/.obsidian/app.json'), '\n'))
    end)
    return vault .. '/' .. (ok and app.attachmentFolderPath or 'assets')
  end
  return vim.fn.expand '%:p:h' .. '/assets'
end

-- pandoc to a file next to the note; a PDF opens in zathura
local function export()
  vim.ui.select({ 'pdf', 'docx', 'html' }, { prompt = 'Export to' }, function(format)
    if not format then
      return
    end
    vim.cmd 'silent update'
    local src = vim.api.nvim_buf_get_name(0)
    local out = vim.fn.fnamemodify(src, ':r') .. '.' .. format
    local cmd = { 'pandoc', src, '-o', out, '--standalone', '--resource-path', vim.fs.dirname(src) }
    if format == 'pdf' then -- xelatex and Noto: Russian and English in one PDF
      vim.list_extend(cmd, { '--pdf-engine=xelatex', '-V', 'mainfont=Noto Serif', '-V', 'geometry:margin=2cm' })
    end
    vim.notify('Exporting to ' .. format .. '…')
    vim.system(cmd, {}, function(r)
      vim.schedule(function()
        if r.code ~= 0 then
          return vim.notify('pandoc failed:\n' .. r.stderr, vim.log.levels.ERROR)
        end
        vim.notify('Exported ' .. vim.fn.fnamemodify(out, ':~:.'))
        if format == 'pdf' then
          vim.system({ 'zathura', out }, { detach = true })
        end
      end)
    end)
  end)
end

return {
  { 'folke/which-key.nvim', opts = { spec = { { '<leader>m', group = 'prose' } } } },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    keys = { { '<leader>mr', '<cmd>RenderMarkdown toggle<cr>', desc = 'Rendering on/off' } },
    opts = {
      render_modes = { 'n', 'c', 't', 'i', 'v', 'V', '\22' },
      latex = { enabled = false }, -- snacks.image draws math as images
      code = { sign = false, width = 'full', right_pad = 1, border = 'none' },
      heading = { sign = false, icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' } },
      checkbox = {
        custom = {
          todo = { raw = '[-]', rendered = '󰄱 ', highlight = 'RenderMarkdownTodo' },
          done = { raw = '[x]', rendered = '󰄲 ', highlight = 'RenderMarkdownDone' },
        },
      },
    },
  },
  {
    'folke/snacks.nvim',
    init = function()
      -- mermaid-cli renders with the installed Chrome instead of its own download
      local chrome = vim.fn.exepath 'google-chrome-stable'
      if vim.env.PUPPETEER_EXECUTABLE_PATH == nil and chrome ~= '' then
        vim.env.PUPPETEER_EXECUTABLE_PATH = chrome
      end
    end,
    opts = {
      image = {
        enabled = vim.g.kitty_graphics,
        math = { enabled = true },
        -- ![[map.png]] in a project note: the image in notes/
        resolve = function(file, src)
          return require('project_notes').asset(file, src)
        end,
      },
    },
  },
  {
    'HakonHarnes/img-clip.nvim',
    cmd = 'PasteImage',
    keys = { { '<leader>mp', '<cmd>PasteImage<cr>', desc = 'Paste an image (screenshot)' } },
    opts = {
      default = { dir_path = image_dir, relative_template_path = true },
      custom = {
        {
          trigger = function()
            return require('project_notes').paste_dir(vim.api.nvim_buf_get_name(0)) ~= nil
          end,
          dir_path = function()
            return require('project_notes').paste_dir(vim.api.nvim_buf_get_name(0))
          end,
          template = '![[$FILE_NAME]]',
        },
      },
    },
  },
  {
    'folke/snacks.nvim',
    keys = { { '<leader>me', export, desc = 'Export (PDF, DOCX, HTML)' } },
  },
}
