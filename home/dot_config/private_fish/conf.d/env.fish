# Environment for every fish, login or not. PATH is in path.fish.
set -gx EDITOR nvim
# bat, fzf (and LS_COLORS, fish's theme) use the terminal's 16 colors, so kitty's
# light/dark switch (theme-switcher) carries over, fzf previews included.
set -gx BAT_THEME ansi
set -gx FZF_DEFAULT_OPTS --color=16
test -f ~/.config/ripgrep/config; and set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config
# Colored man pages: col strips man's overstrike formatting, bat highlights it
command -q bat; and command -q col; and set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx GTEST_COLOR 1
set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1
test -d ~/Android/Sdk; and set -gx ANDROID_HOME ~/Android/Sdk

# API keys (age-encrypted in the dotfiles; only on machines with personal=true)
test -f ~/.config/fish/private.fish; and source ~/.config/fish/private.fish
