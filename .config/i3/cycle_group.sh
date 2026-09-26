#!/bin/bash
# Show the next or previous workspace group on all monitors at once, keeping focus
# on the current monitor. Groups and the monitor order: groups.sh, i3-outputs.
#
#   cycle_group.sh next|prev
#   cycle_group.sh --plan next|prev <ws> <output> <outputs...>
#       print the i3 command for that state instead of running it (for tests)
here=$(dirname "$(readlink -f "$0")")
. "$here/groups.sh"

# plan <direction> <focused ws> <focused output> <outputs left to right...>
plan() {
    local dir=$1 ws=$2 current=$3
    shift 3
    local outputs=("$@") n=$# group i cmd="" last=""
    ((n > 0)) || return 1
    ((ws >= 1)) || ws=1 # a named workspace counts as group 0
    group=$(((ws - 1) / n))
    case $dir in
        next) group=$(((group + 1) % GROUP_COUNT)) ;;
        prev) group=$(((group - 1 + GROUP_COUNT) % GROUP_COUNT)) ;;
        *) return 1 ;;
    esac
    # Switch the other monitors first and the focused one last, so focus stays put.
    for i in "${!outputs[@]}"; do
        if [[ ${outputs[i]} == "$current" ]]; then
            last="workspace number $((group * n + i + 1))"
        else
            cmd+="workspace number $((group * n + i + 1)); "
        fi
    done
    [[ -n $last ]] || { echo "cycle_group: $current is not an active monitor" >&2; return 1; }
    echo "$cmd$last"
}

if [[ $1 == --plan ]]; then
    shift
    plan "$@"
    exit
fi

read -r ws current < <(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | "\(.num) \(.output)"')
mapfile -t outputs < <("$HOME/.local/bin/i3-outputs")
cmd=$(plan "$1" "$ws" "$current" "${outputs[@]}") || exit 1
i3-msg -q "$cmd"
