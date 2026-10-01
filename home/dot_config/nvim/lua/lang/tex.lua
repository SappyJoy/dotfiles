-- LaTeX: vimtex (compiles as you save, zathura synced both ways: \ll starts, \lv
-- shows the spot; Ctrl+click in zathura jumps back), texlab, latexindent where the
-- project has its config.
return {
  parsers = { 'bibtex' },
  servers = { texlab = {} },
  formatters = { tex = { 'latexindent' } },
  formats_if = { '.latexindent.yaml', 'latexindent.yaml', 'localSettings.yaml' },
  tools = { 'texlab' }, -- latexindent comes with TeX Live
  plugins = {
    {
      'lervag/vimtex',
      lazy = false, -- vimtex's README: lazy loading breaks its filetype and inverse search
      init = function()
        vim.g.vimtex_view_method = 'zathura'
        vim.g.vimtex_compiler_latexmk = {
          options = { '-shell-escape', '-verbose', '-file-line-error', '-synctex=1', '-interaction=nonstopmode' },
        }
        vim.g.vimtex_quickfix_open_on_warning = 0
      end,
    },
  },
}
