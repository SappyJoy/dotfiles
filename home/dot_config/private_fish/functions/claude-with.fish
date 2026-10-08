# Claude Code with one more plugin on, for this session only; no settings file changes.
# `claude-with session-report`, or `claude-with mason-lsp@personal` for another
# marketplace; options after the plugin go to claude.
function claude-with --description 'claude with one more plugin on, for this session'
    set -l id $argv[1]
    # An option first (`--resume`, `-h`) isn't a plugin
    if test -z "$id"; or string match -q -- '-*' $id
        echo 'usage: claude-with <plugin>[@marketplace] [claude options]' >&2
        return 2
    end
    string match -q -- '*@*' $id; or set id $id@claude-plugins-official
    claude --settings "{\"enabledPlugins\":{\"$id\":true}}" $argv[2..]
end
