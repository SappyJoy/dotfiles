# Workspace groups: the contract shared by dynamic_workspaces.sh and cycle_group.sh.
# Sourced, not run.
#
# With N active monitors ordered left to right (i3-outputs), workspace k lives on
# monitor (k - 1) mod N, and group g (from 0) holds workspaces g*N+1 .. g*N+N.
# N is 3 on the home desk, 2 at work and 1 in FILM, where a group is one workspace.
GROUP_COUNT=5
