function cl --description 'New background Claude session here, attached'
    set -l out (claude --bg $argv)
    set -l id (string match -r 'backgrounded · (\w+)' -- $out)[2]
    if test -z "$id"
        printf '%s\n' $out
        return 1
    end
    claude attach $id
end
