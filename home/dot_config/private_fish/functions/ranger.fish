# ranger that leaves the shell in the directory ranger was in when it quit.
function ranger --description 'ranger, then cd to its last directory'
    set -l dirfile (mktemp)
    command ranger --choosedir=$dirfile $argv
    set -l dir (cat $dirfile)
    rm -f $dirfile
    test -n "$dir"; and cd $dir
end
