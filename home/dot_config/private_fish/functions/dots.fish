# Commit dotfile edits: copy live edits into the chezmoi source, list what's left,
# open lazygit on the source.
#
# Only files whose first `chezmoi status` column is M are re-added: those changed
# live since chezmoi last wrote them. A change only in the second column ( M) came
# from the source (a pull, `chezmoi edit`) and needs `chezmoi apply`; re-adding it
# would undo that change. re-add also skips templates: use `chezmoi merge` there.
function dots --description 'Dotfiles: re-add live edits, then lazygit on the source'
    set -l edited
    for line in (chezmoi status)
        switch (string sub -l 2 -- $line)
            case 'M*'
                set -a edited ~/(string sub -s 4 -- $line)
        end
    end
    if set -q edited[1]
        chezmoi re-add $edited; or return
    end

    set -l left (chezmoi status)
    if set -q left[1]
        echo "Still differs (first column M: template, use chezmoi merge; else chezmoi apply):"
        printf '  %s\n' $left
    end
    lazygit -p ~/.local/share/chezmoi
end
