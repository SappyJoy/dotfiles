#!/bin/sh
# Guest mode: these dotfiles and tools on someone else's machine, then a clean exit.
#
#   install  Back up the files chezmoi would overwrite, then apply with desktop=false
#            and personal=false (no i3 stack, no secrets). Run it again to update.
#   remove   Undo it: restore the backed-up files, then delete what chezmoi, mise,
#            fisher and the tools created, chezmoi included.
#
# Files you make yourself stay, and so do directories that aren't empty. What it
# created is recorded in ~/.guest-dotfiles until remove.
#
#   curl -fsLS https://raw.githubusercontent.com/SappyJoy/dotfiles/master/guest.sh | sh -s install
#   sh ~/.local/share/chezmoi/guest.sh remove
#
# DOTFILES_REPO: what to init from (default SappyJoy). A local directory is copied
# as is, uncommitted changes included (tests).

set -eu

state=$HOME/.guest-dotfiles
# Data and caches the tools write; remove deletes those that didn't exist before.
tool_dirs='.config/chezmoi .local/share/chezmoi .cache/chezmoi
.config/mise .local/share/mise .local/state/mise .cache/mise .cache/sigstore-rust
.config/fish .local/share/fish .cache/fish
.tmux .local/share/nvim .local/state/nvim .cache/nvim
.local/share/uv .cache/uv .local/share/zoxide .local/state/lazygit'
tool_files='.bash_eternal_history'
# Their parents; removed only when they didn't exist before and are empty.
parent_dirs='.local/bin .local/share .local/state .local .config .cache'

die() { echo "guest: $*" >&2; exit 1; }

# existed PATH: PATH (relative to ~) was there before the first install
existed() { grep -qxF "$1" "$state/existed"; }

chezmoi_cmd() {
    command -v chezmoi 2>/dev/null || echo "$HOME/.local/bin/chezmoi"
}

install() {
    if [ ! -d "$state" ]; then
        for d in .config/chezmoi .local/share/chezmoi; do
            [ ! -e "$HOME/$d" ] || die "~/$d exists: chezmoi is set up here already"
        done
        mkdir -p "$state/backup"
        : >"$state/created"
        for p in $tool_dirs $tool_files $parent_dirs; do
            if [ -e "$HOME/$p" ]; then echo "$p"; fi
        done >"$state/existed"
    fi

    cz=$(chezmoi_cmd)
    if [ ! -x "$cz" ]; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
        echo "f .local/bin/chezmoi" >>"$state/created"
    fi

    repo=${DOTFILES_REPO:-SappyJoy}
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        if [ -d "$repo" ]; then
            mkdir -p "$HOME/.local/share"
            cp -r "$repo" "$HOME/.local/share/chezmoi"
            set --
        else
            set -- "$repo"
        fi
        # --promptBool matches the prompt texts in home/.chezmoi.toml.tmpl
        "$cz" init --promptBool 'Desktop (X11 + i3)=false,Own machine (secrets)=false' "$@"
    elif [ ! -d "$repo" ]; then
        "$cz" git -- pull --ff-only --quiet
    fi

    # Back up what apply would overwrite; note what it will create.
    backup_or_note f files,symlinks "$cz"
    backup_or_note d dirs "$cz"
    "$cz" apply
    echo "guest: installed. Undo with: sh ~/.local/share/chezmoi/guest.sh remove"
}

# backup_or_note TYPE INCLUDE CHEZMOI: for each target chezmoi manages (of the kinds in
# INCLUDE), keep a copy of an existing file, or record a missing one as created.
backup_or_note() {
    "$3" managed --include "$2" --path-style absolute | while IFS= read -r path; do
        rel=${path#"$HOME"/}
        if grep -qxF "$1 $rel" "$state/created" ||
            [ -e "$state/backup/$rel" ] || [ -L "$state/backup/$rel" ]; then
            continue
        fi
        if [ -e "$path" ] || [ -L "$path" ]; then
            [ "$1" = d ] && continue # an existing directory stays as it is
            mkdir -p "$(dirname "$state/backup/$rel")"
            cp -Pp "$path" "$state/backup/$rel"
        else
            echo "$1 $rel" >>"$state/created"
        fi
    done
}

remove() {
    [ -d "$state" ] || die "no guest install here (~/.guest-dotfiles is missing)"

    # Files chezmoi created (and chezmoi itself), then the originals back in place.
    sed -n 's/^f //p' "$state/created" | while IFS= read -r rel; do
        rm -f "$HOME/$rel"
    done
    (cd "$state/backup" && find . ! -type d) | while IFS= read -r rel; do
        rel=${rel#./}
        rm -f "$HOME/$rel"
        cp -Pp "$state/backup/$rel" "$HOME/$rel"
    done

    for p in $tool_dirs $tool_files; do
        existed "$p" || rm -rf "${HOME:?}/$p"
    done
    # Directories chezmoi created, deepest first, then the parents: only when empty.
    { sed -n 's/^d //p' "$state/created"; for p in $parent_dirs; do existed "$p" || echo "$p"; done; } |
        awk '{ print length($0), $0 }' | sort -rn | cut -d ' ' -f 2- |
        while IFS= read -r rel; do
            if [ -d "$HOME/$rel" ] && ! rmdir "$HOME/$rel" 2>/dev/null; then
                echo "guest: kept ~/$rel (not empty)"
            fi
        done

    rm -rf "$state"
    echo "guest: removed"
}

case ${1:-} in
    install) install ;;
    remove) remove ;;
    *) echo "usage: guest.sh install|remove (see the comments at the top)" >&2; exit 2 ;;
esac
