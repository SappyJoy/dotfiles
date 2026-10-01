-- Go: gopls; goimports and gofmt are Go's convention, so every module formats.
return {
  parsers = { 'go', 'gomod', 'gosum', 'gowork' },
  servers = { gopls = { settings = { gopls = { usePlaceholders = true } } } },
  formatters = { go = { 'goimports', 'gofmt' } },
  formats_if = { 'go.mod' },
  tools = { { 'gopls', need = 'go' }, { 'goimports', need = 'go' }, { 'delve', need = 'go' } },
}
