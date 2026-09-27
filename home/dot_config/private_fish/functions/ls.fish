# ls is lsd where lsd is installed (config in ~/.config/lsd), plain ls elsewhere.
function ls --wraps lsd --description 'lsd, or ls where lsd is missing'
    if command -q lsd
        command lsd $argv
    else
        command ls --color=auto $argv
    end
end
