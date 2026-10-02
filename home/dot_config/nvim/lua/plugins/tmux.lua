-- Ctrl+arrows (and Ctrl+\ for the last one) move between nvim windows and tmux panes
-- alike; tmux.conf has the other half.
local function nav(dir)
  return '<cmd>TmuxNavigate' .. dir .. '<cr>'
end

return {
  'christoomey/vim-tmux-navigator',
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { '<C-Left>', nav 'Left', mode = { 'n', 't' }, desc = 'Window/pane left' },
    { '<C-Down>', nav 'Down', mode = { 'n', 't' }, desc = 'Window/pane down' },
    { '<C-Up>', nav 'Up', mode = { 'n', 't' }, desc = 'Window/pane up' },
    { '<C-Right>', nav 'Right', mode = { 'n', 't' }, desc = 'Window/pane right' },
    { '<C-\\>', nav 'Previous', mode = { 'n', 't' }, desc = 'Last window/pane' },
  },
}
