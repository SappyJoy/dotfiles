function plog --description "Show logcat filtered by package name using pidcat, optionally grep with rg"
    # Check dependencies
    if not type -q pidcat
        echo "Error: pidcat is not installed or not in PATH." >&2
        echo "Please install it: pip install pidcat" >&2
        return 1
    end

    # Check for package name argument
    if test (count $argv) -eq 0
        echo "Usage: plog <package.name> [search terms...]" >&2
        echo "Example: plog com.example.app MyActivity" >&2
        echo "Example: plog com.example.app # Shows all logs for package" >&2
        return 1
    end

    set -l package $argv[1]
    set -l search_args $argv[2..]

    echo -e "\e[1;34mStarting pidcat for package:\e[0m $package" # Bold Blue

    if test (count $search_args) -gt 0
        if type -q rg
            echo -e "\e[1;34mFiltering output for:\e[0m $search_args"
            # Use --color=always for rg when piping is involved internally or might be later
            # Use --line-buffered to ensure lines appear ASAP
            # Use stdbuf -o0 pidcat if you experience buffering delays before rg sees output
            pidcat $package | rg --color=always --line-buffered -i $search_args
        else
            echo "\e[1;33mWarning:\e[0m rg (ripgrep) not found. Cannot filter output. Showing all logs for $package." >&2
            echo "Consider installing ripgrep for search capabilities." >&2
            pidcat $package
        end
    else
        # No search terms, just run pidcat
        pidcat $package
    end
end
