#!/bin/bash
# Assign workspaces to the active monitors (contract: groups.sh), write the
# assignments to dynamic_workspaces.conf and reload i3 if they changed.
#
#   dynamic_workspaces.sh              write + reload i3 on change (i3 exec_always)
#   dynamic_workspaces.sh --no-reload  write only: run it before an i3 restart that
#                                      follows a monitor change, and the restarted
#                                      i3 moves existing workspaces to their monitors
#   dynamic_workspaces.sh --dry-run    print the assignments, change nothing
#
# I3_OUTPUTS="A B" (see i3-outputs) fakes the monitors for a dry run.
here=$(dirname "$(readlink -f "$0")")
. "$here/groups.sh"
conf=$here/dynamic_workspaces.conf

mapfile -t outputs < <("$HOME/.local/bin/i3-outputs") || exit 1
n=${#outputs[@]}
((n > 0)) || exit 1

new=$(for ((k = 1; k <= GROUP_COUNT * n; k++)); do
    echo "workspace $k output ${outputs[(k - 1) % n]}"
done)

case $1 in
    --dry-run) printf '%s\n' "$new"; exit 0 ;;
    --no-reload | "") ;;
    *) echo "usage: dynamic_workspaces.sh [--no-reload|--dry-run]" >&2; exit 2 ;;
esac

[[ -f $conf && $(<"$conf") == "$new" ]] && exit 0
printf '%s\n' "$new" > "$conf"
[[ $1 == --no-reload ]] || i3-msg -q reload
