function flog --description "Interactively select package (fzf), show logcat (pidcat), optionally grep (rg)"
    # Check dependencies
    if not type -q pidcat; or not type -q adb; or not type -q fzf
        echo "Error: Missing dependencies. Need: pidcat, adb, fzf" >&2
        echo "Please install them." >&2
        return 1
    end

    # Get 3rd party packages, use fzf to select one
    echo "Fetching packages..." >&2
    set -l pkg (adb shell pm list packages -3 | sed 's/package://' | sort | fzf --prompt="Select package> " --height=40% --border --header="Select Android application package:")

    # Check if a package was selected
    if test -z "$pkg"
        echo "No package selected." >&2
        return 1
    end

    echo -e "\e[1;34mSelected package:\e[0m $pkg"

    # Ask for optional search terms
    read -P "Enter search terms (optional, press Enter for all logs): " search_terms

    if test -n "$search_terms"
        if type -q rg
            echo -e "\e[1;34mFiltering output for:\e[0m $search_terms"
            pidcat $pkg | rg --color=always --line-buffered -i $search_terms
        else
            echo "\e[1;33mWarning:\e[0m rg (ripgrep) not found. Cannot filter output. Showing all logs for $pkg." >&2
            echo "Consider installing ripgrep for search capabilities." >&2
            pidcat $pkg
        end
    else
        # No search terms, just run pidcat
        pidcat $pkg
    end
end
