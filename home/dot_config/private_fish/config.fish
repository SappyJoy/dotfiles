# fish config, split by role:
#   conf.d/env.fish        environment variables (+ private.fish)
#   conf.d/path.fish       PATH
#   conf.d/ls_colors.fish  LS_COLORS
#   conf.d/abbr.fish       shortcuts, expanded on the command line
#   functions/*.fish       one function per file, loaded on first use
#   themes/sap.theme       colors
# Plugins: fish_plugins (fisher). The tide prompt style: run_onchange_after_26-tide.sh.
# This file keeps only what has to run last, in interactive shells.

if status is-interactive
    set -g fish_greeting
    # Default (emacs-style) keys. Set here because fish >= 4.3 dropped the universal
    # variable: while it's empty, tide draws its vi-mode ❮ and puffer-fish binds its
    # keys for vi insert mode.
    set -g fish_key_bindings fish_default_key_bindings
    fish_config theme choose sap
    command -q zoxide; and zoxide init fish | source
end
