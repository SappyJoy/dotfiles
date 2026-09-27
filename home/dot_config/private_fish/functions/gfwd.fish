# The opposite of `gback`: check out the next commit on the way to <ref>.
function gfwd --description 'git: check out the next commit toward <ref>'
    git checkout (git rev-list --topo-order HEAD..$argv[1] | tail -1)
end
