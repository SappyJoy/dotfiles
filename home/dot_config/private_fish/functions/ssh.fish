# Remote hosts rarely know kitty's or tmux's terminfo (xterm-kitty, tmux-256color),
# and then backspace, clear and colors break there. Every host knows xterm-256color.
# (kitty's `kitten ssh` copies the terminfo over instead, where a host allows it.)
function ssh --wraps ssh --description 'ssh with TERM=xterm-256color'
    TERM=xterm-256color command ssh $argv
end
