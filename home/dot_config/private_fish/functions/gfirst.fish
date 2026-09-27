function gfirst --description 'git: check out the first commit'
    git checkout (git rev-list --max-parents=0 HEAD | tail -n 1)
end
