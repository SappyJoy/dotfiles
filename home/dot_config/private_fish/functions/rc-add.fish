function rc-add --description 'Let the phone start Claude sessions in a project: rc-add [dir]'
    set -l dir .
    set -q argv[1]; and set dir $argv[1]
    set -l top (git -C $dir rev-parse --show-toplevel 2>/dev/null)
    if test -z "$top"
        echo "rc-add: $dir is not in a git repo (phone sessions get their own worktree)" >&2
        return 1
    end
    systemctl --user enable --now claude-remote-control@(systemd-escape -p $top)
end
