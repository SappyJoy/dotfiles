-- Shell: bash-language-server (shellcheck's warnings come through it), shfmt on a
-- key only (scripts rarely say how they're formatted).
return {
  parsers = { 'bash' },
  servers = { bashls = {} },
  formatters = { sh = { 'shfmt' }, bash = { 'shfmt' } },
  tools = { { 'bash-language-server', need = 'npm' }, 'shellcheck', 'shfmt' },
}
