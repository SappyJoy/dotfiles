-- Rust: rust-analyzer; rustfmt (from rustup) is Rust's convention, so every Cargo
-- project formats.
return {
  parsers = { 'rust', 'toml' },
  servers = { rust_analyzer = {} },
  formatters = { rust = { 'rustfmt' } },
  formats_if = { 'Cargo.toml' },
  tools = { 'rust-analyzer' },
}
