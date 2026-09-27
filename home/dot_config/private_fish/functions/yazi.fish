# yazi that leaves the shell in the directory yazi was in when it quit with q (Q quits
# without). Same idea as the ranger function.
function yazi --wraps yazi --description 'yazi, then cd to its last directory'
    set -l dirfile (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file=$dirfile
    set -l dir (cat $dirfile)
    rm -f $dirfile
    if test -n "$dir"; and test "$dir" != "$PWD"
        cd $dir
    end
end
