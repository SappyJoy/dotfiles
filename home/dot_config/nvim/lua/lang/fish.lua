-- fish: fish_indent is fish's own formatter, so fish files always format.
return {
  parsers = { 'fish' },
  formatters = { fish = { 'fish_indent' } },
  formats_if = true,
}
