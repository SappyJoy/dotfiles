-- Typst: tinymist (language server with its own compiler) writes the PDF on every
-- save; \lv opens it in zathura, which reloads it after each save (Typst has no
-- synctex, so no cursor sync). typstyle formats.
return {
  parsers = { 'typst' },
  servers = { tinymist = { settings = { formatterMode = 'typstyle', exportPdf = 'onSave' } } },
  formatters = { typst = { 'typstyle' } },
  formats_if = { 'typst.toml' },
  tools = { 'tinymist', 'typstyle' },
  ftplugin = {
    typst = function(buf)
      vim.keymap.set('n', '<localleader>lv', function()
        local pdf = vim.fn.expand '%:p:r' .. '.pdf'
        if vim.uv.fs_stat(pdf) then
          vim.system({ 'zathura', pdf }, { detach = true })
        else
          vim.notify 'No PDF yet: save once (tinymist writes it on save)'
        end
      end, { buffer = buf, desc = 'PDF in zathura' })
    end,
  },
}
