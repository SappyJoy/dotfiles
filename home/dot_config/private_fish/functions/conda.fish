# conda's shell hook costs ~0.9 s, so it loads on the first `conda` call instead of
# in every shell. auto_activate_base is off, so nothing else changes.
function conda --description 'conda (loads its shell hook on first use)'
    if not test -x /opt/miniconda3/bin/conda
        echo "conda: /opt/miniconda3 is not installed" >&2
        return 127
    end
    set -l hook (/opt/miniconda3/bin/conda shell.fish hook); or return
    # The hook defines the real `conda` function, replacing this one.
    printf '%s\n' $hook | source
    conda $argv
end
