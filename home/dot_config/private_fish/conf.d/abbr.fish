# Shortcuts that expand on the command line (type `g` + Space → `git`), so history
# and copy-paste show the real command. Wrappers that change behavior (ls, ranger,
# claude) are functions in functions/.
status is-interactive; or return

# editor
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim
abbr -a view nvim -R
abbr -a vimdiff nvim -d

# git
abbr -a g git
abbr -a lg lazygit
abbr -a gback git checkout HEAD~

# dotfiles (chezmoi, source in ~/.local/share/chezmoi); commit edits with `dots`
abbr -a gd chezmoi git --
abbr -a lgd lazygit -p ~/.local/share/chezmoi
abbr -a vd chezmoi edit --apply

# directories: zoxide is cd (config.fish); z and zi from the old habit
abbr -a z cd
abbr -a zi cdi

# files
abbr -a r ranger
abbr -a d dir2md
abbr -a ll ls -l
abbr -a lr 'ls -lt --color=always | head'

# clipboard
abbr -a c xclip -selection clipboard
abbr -a clip xclip -selection clipboard

# network
abbr -a vpn-on nmcli connection up vpnconfig
abbr -a vpn-off nmcli connection down vpnconfig
