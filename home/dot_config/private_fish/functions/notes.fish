# A repo's notes/ in the browser: one shared Quartz serves them with the link graph,
# backlinks, hover previews, search and live reload. Each repo gets its own server,
# port and output folder, so several can be open at once; the server keeps running
# in the background until `notes stop` (or a reboot).
#
#   notes          start this repo's server, or reuse it, and open the index
#   notes FILE     the same, and open FILE's page (nvim's <leader>po)
#   notes stop     stop this repo's server
#
# The first run clones Quartz into ~/.local/share/quartz and installs it with its
# plugins: several minutes, and it needs GitHub, where each plugin is a repo. The
# config is ~/.config/quartz/quartz.config.yaml; a server reads it when it starts.
# To reinstall (another release), remove the install.
# A server's log, port and pages are in ~/.cache/notes/<repo>-<hash>/.
# NOTES_QUARTZ_REPO clones Quartz from elsewhere (tests).
function notes --description "This repo's notes in the browser (Quartz)"
    set -l release v5.0.0
    set -l quartz (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo ~/.local/share)/quartz
    set -l config (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo ~/.config)/quartz
    set -l cache (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo ~/.cache)/notes

    set -l file
    set -l dir .
    if test -n "$argv[1]"; and test "$argv[1]" != stop
        set file (path resolve -- $argv[1])
        set dir (path dirname -- $file)
    end
    set -l root (git -C $dir rev-parse --show-toplevel 2>/dev/null)
    if test -z "$root"
        echo 'notes: not in a git repo' >&2
        return 1
    end
    set -l notes $root/notes
    if not test -d $notes
        echo "notes: $root has no notes/" >&2
        return 1
    end
    set -l hash (echo -n $root | md5sum | string sub -l 8)
    set -l state $cache/(path basename -- $root)-$hash
    mkdir -p $state

    # this repo's server: the pid in the state folder, if it still serves these notes
    set -l pid (cat $state/pid 2>/dev/null)
    set -l running false
    if test -n "$pid"; and test -r /proc/$pid/cmdline
        set -l args (string split0 </proc/$pid/cmdline)
        contains -- quartz/bootstrap-cli.mjs $args; and contains -- $notes $args; and set running true
    end

    if test "$argv[1]" = stop
        if test $running = true
            kill $pid
            echo "notes: stopped the server for $notes"
        else
            echo "notes: no server runs for $notes"
        end
        rm -f $state/pid
        return 0
    end

    if not test -e $quartz/.notes-installed
        echo "notes: installing Quartz $release and its plugins into $quartz, once:"
        echo "notes: it takes several minutes and needs GitHub"
        if not test -e $quartz/package.json
            set -l repo https://github.com/jackyzha0/quartz.git
            set -q NOTES_QUARTZ_REPO; and set repo $NOTES_QUARTZ_REPO
            git -c advice.detachedHead=false clone -q --depth 1 --branch $release $repo $quartz
            or return 1
        end
    end
    # the site's title is the repo's name
    string replace -a '{{repo}}' (path basename -- $root) <$config/quartz.config.yaml >$quartz/quartz.config.yaml
    or return 1
    if not test -e $quartz/.notes-installed
        # in Quartz's folder, so mise takes the node its .node-version pins; npm 11 and
        # later refuse git dependencies, which Quartz and its plugins have, so they are
        # allowed for these commands only
        env -C $quartz npm_config_allow_git=all npm ci --no-audit --no-fund --loglevel=error
        or return 1
        # it ends with "Installed N plugin(s)", and ", M failed" if some couldn't be
        # cloned or built, but its status is 0 either way
        set -l log $quartz/.notes-install.log
        env -C $quartz npm_config_allow_git=all node quartz/bootstrap-cli.mjs plugin install | tee $log
        if not string match -q -- '*Installed*' <$log; or string match -q -- '*failed*' <$log
            echo 'notes: some plugins failed to install; run notes again to retry' >&2
            return 1
        end
        touch $quartz/.notes-installed
    end

    if test $running = false
        # a port from the repo's hash, so its pages keep their address; the next free
        # pair if taken (the page, and its live-reload socket one above)
        set -l port (math "8100 + 2 * (0x"(string sub -l 4 $hash)" % 200)")
        while ss -Hltn "( sport = :$port or sport = :$(math $port + 1) )" | string length -q
            set port (math $port + 2)
        end
        echo "notes: serving $notes"
        env -C $quartz nohup node quartz/bootstrap-cli.mjs \
            build --serve -d $notes -o $state/public --port $port --wsPort (math $port + 1) </dev/null >$state/log 2>&1 &
        set pid $last_pid
        disown $pid
        echo $pid >$state/pid
        echo $port >$state/port
        # Quartz listens once its first build is done
        set -l tries 600
        while not curl -sf -o /dev/null http://localhost:$port/
            if not kill -0 $pid 2>/dev/null
                echo "notes: Quartz stopped; the end of its log ($state/log):" >&2
                tail -n 20 $state/log >&2
                rm -f $state/pid
                return 1
            end
            set tries (math $tries - 1)
            if test $tries -eq 0
                echo "notes: Quartz isn't up after 2 minutes; its log: $state/log" >&2
                return 1
            end
            sleep 0.2
        end
    end

    # FILE's page: its path in notes/ as Quartz slugs it; index.md is its folder
    set -l page ''
    if test -n "$file"; and string match -q -- "$notes/*.md" $file
        set page (string replace -- "$notes/" '' $file | string replace -r '\.md$' '' \
            | string replace -r '(^|/)index$' '$1' | string replace -a -- ' ' - \
            | string replace -a -- '&' -and- | string replace -a -- '%' -percent \
            | string replace -ar '[?#]' '')
    end
    set -l url http://localhost:(cat $state/port)/$page
    echo "notes: $url"
    if command -q xdg-open
        xdg-open $url >/dev/null 2>&1 &
        disown $last_pid
    end
end
