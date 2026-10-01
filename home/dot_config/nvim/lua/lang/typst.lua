-- Typst: tinymist (language server with its own compiler), typstyle.
return {
  parsers = { 'typst' },
  servers = { tinymist = { settings = { formatterMode = 'typstyle' } } },
  formatters = { typst = { 'typstyle' } },
  formats_if = { 'typst.toml' },
  tools = { 'tinymist', 'typstyle' },
}
