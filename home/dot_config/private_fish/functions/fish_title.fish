# Terminal title: the directory at the prompt, the command + directory while it runs.
function fish_title
    if test "$_" = fish
        echo (prompt_pwd)
    else
        echo (status current-command) (prompt_pwd)
    end
end
