# fish config, split by role:
#   conf.d/env.fish        environment variables (+ private.fish)
#   conf.d/path.fish       PATH
#   conf.d/ls_colors.fish  LS_COLORS
#   conf.d/abbr.fish       shortcuts, expanded on the command line
#   functions/*.fish       one function per file, loaded on first use
#   themes/sap.theme       colors
# Plugins: fish_plugins (fisher). The tide prompt style: run_onchange_after_26-tide.sh.
# This file keeps only what has to run last.

# Default (emacs-style) keys. fish >= 4.3 dropped the universal variable, and while
# it's empty tide draws its vi-mode ❮ and puffer-fish binds its keys for vi insert
# mode. Set in every fish, not only interactive ones: tide renders the prompt line
# with ❯ in a background `fish -c`.
set -g fish_key_bindings fish_default_key_bindings

if status is-interactive
    set -g fish_greeting
    fish_config theme choose sap
    # zoxide as cd: a path works as before, `cd foo` jumps to the most used dir
    # matching foo, `cdi` picks one with fzf. fish's cd (dir history, cd -) stays
    # underneath. Abbreviations in abbr.fish turn z/zi into cd/cdi.
    command -q zoxide; and zoxide init fish --cmd cd | source
end
