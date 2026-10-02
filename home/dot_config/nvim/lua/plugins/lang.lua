-- What only one language needs, declared in its lang/ file: plugins, filetypes,
-- buffer settings (ftplugin).
local specs = {}
for _, lang in pairs(require('lang').all()) do
  vim.list_extend(specs, lang.plugins or {})
  if lang.filetypes then
    vim.filetype.add(lang.filetypes)
  end
  for ft, setup in pairs(lang.ftplugin or {}) do
    vim.api.nvim_create_autocmd('FileType', {
      pattern = ft,
      callback = function(args)
        setup(args.buf)
      end,
    })
  end
end
return specs
