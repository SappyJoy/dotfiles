# fish runs this after loading its key bindings.
function fish_user_key_bindings
    # Shift+Enter runs the line, as before: kitty now sends it as a CSI u code
    # (kitty.conf, for nvim inside tmux), which fish has no binding for.
    bind shift-enter execute
end
