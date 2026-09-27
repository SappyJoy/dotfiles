# The mise shims (tools pinned in tools.tsv, non-arch machines), then ~/.local/bin
# (chezmoi, tools-check, tracked scripts) in front of them. -g keeps them out of the
# universal fish_user_paths, which a fresh machine doesn't have.
test -d ~/.local/share/mise/shims; and fish_add_path -g ~/.local/share/mise/shims
fish_add_path -g ~/.local/bin
