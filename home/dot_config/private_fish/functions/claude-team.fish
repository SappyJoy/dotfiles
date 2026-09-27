# Claude Code: team account (default ~/.claude + ~/.claude.json)
function claude-team --description 'Claude Code (team account)'
    env -u CLAUDE_CONFIG_DIR claude $argv
end
