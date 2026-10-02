-- Dockerfiles: hadolint.
return {
  parsers = { 'dockerfile' },
  linters = { dockerfile = { 'hadolint' } },
  tools = { 'hadolint' },
}
