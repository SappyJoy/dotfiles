# Tool dirs outside the system paths, where present: npm's global prefix (~/.npmrc),
# and adb from the Android SDK, in front of pacman's android-tools (as in ~/.profile).
for dir in ~/.npm-global/bin ~/Android/Sdk/platform-tools
    test -d $dir; and fish_add_path -g $dir
end

# The mise shims (tools pinned in tools.tsv, non-arch machines), then ~/.local/bin
# (chezmoi, tools-check, tracked scripts) in front of them. -g keeps them out of the
# universal fish_user_paths, which a fresh machine doesn't have.
test -d ~/.local/share/mise/shims; and fish_add_path -g ~/.local/share/mise/shims
fish_add_path -g ~/.local/bin
