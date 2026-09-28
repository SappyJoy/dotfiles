# Commit dotfile edits: add new files, copy live edits into the chezmoi source, list
# what's left with what to do about it, open lazygit on the source.
#
# `dots FILE…` first adds the FILEs that chezmoi doesn't manage yet (like `git add`
# with the old bare repo). Managed ones are left to re-add below: `chezmoi add` would
# turn a template into a plain file.
#
# Only files whose first `chezmoi status` column is M are re-added: those changed
# live since chezmoi last wrote them. A change only in the second column ( M) came
# from the source (a pull, `chezmoi edit`, a branch) and needs `chezmoi apply`;
# re-adding it would undo that change. re-add skips templates and files the machine
# owns (modify_), so those are listed with the command that takes them.
function dots --description 'Dotfiles: add FILEs, re-add live edits, then lazygit on the source'
    for file in $argv
        if not chezmoi source-path $file >/dev/null 2>&1
            chezmoi add $file; or return
        end
    end

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

    set -l pending
    set -l here
    for line in (chezmoi status)
        if test (string sub -l 1 -- $line) = ' '
            set -a pending $line
            continue
        end
        set -l file '~/'(string sub -s 4 -- $line)
        switch (chezmoi source-path ~/(string sub -s 4 -- $line) 2>/dev/null)
            case '*.tmpl'
                set -a here "$line  (template: chezmoi merge $file)"
            case '*/modify_*'
                set -a here "$line  (this machine's own: chezmoi apply $file keeps the edit)"
            case '*'
                set -a here "$line  (chezmoi forget $file, or chezmoi apply $file to restore)"
        end
    end
    if set -q pending[1]
        echo "Not in your home yet (chezmoi diff shows it, chezmoi apply writes it):"
        printf '  %s\n' $pending
    end
    if set -q here[1]
        echo "Changed here, not copied to the source:"
        printf '  %s\n' $here
    end
    lazygit -p ~/.local/share/chezmoi
end
