# Environment for every fish, login or not. PATH is in path.fish.
set -gx EDITOR nvim
set -gx BAT_THEME OneHalfLight
set -gx GTEST_COLOR 1
set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1
test -d ~/Android/Sdk; and set -gx ANDROID_HOME ~/Android/Sdk

# API keys (age-encrypted in the dotfiles; only on machines with personal=true)
test -f ~/.config/fish/private.fish; and source ~/.config/fish/private.fish
