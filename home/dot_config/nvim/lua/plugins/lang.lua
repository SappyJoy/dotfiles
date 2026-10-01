-- The plugins that only one language needs, declared in its lang/ file.
local specs = {}
for _, lang in pairs(require('lang').all()) do
  vim.list_extend(specs, lang.plugins or {})
  if lang.filetypes then
    vim.filetype.add(lang.filetypes)
  end
end
return specs
