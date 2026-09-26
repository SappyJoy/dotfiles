#!/bin/sh
#
# setup_dotfiles.sh: Clones dotfiles/secrets and configures the system.
# Requires: git, curl, fish (optional, for plugin setup)
# Usage: ./setup_dotfiles.sh
# Recommended: Run from a temporary directory, not $HOME directly.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Use full paths for clarity, especially since $HOME might expand differently
# depending on execution context. Using `eval` handles ~ expansion reliably.
DOTFILES_BARE_PATH=$(eval echo "~/.dotfiles")
SECRETS_BARE_PATH=$(eval echo "~/.secrets")
DOTFILES_REPO_SSH="git@github.com:SappyJoy/.dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/SappyJoy/.dotfiles.git"
SECRETS_REPO="git@github.com:SappyJoy/.secrets.git" # Optional secrets repo

_log() {
    echo "[SETUP] $1"
}

_git_cmd() {
    # Helper to run git commands with specific bare repos
    # Usage: _git_cmd dotfiles <args...> OR _git_cmd secrets <args...>
    local repo_type=$1
    shift # Remove repo_type from arguments
    local git_dir

    if [ "$repo_type" = "dotfiles" ]; then
        git_dir="$DOTFILES_BARE_PATH"
    elif [ "$repo_type" = "secrets" ]; then
        git_dir="$SECRETS_BARE_PATH"
    else
        _log "Error: Invalid repo type '$_repo_type' for _git_cmd"
        return 1
    fi

    # Ensure HOME is explicitly passed for work-tree if needed
    # Although --work-tree=$HOME is common, be mindful of script execution context
    git --git-dir="$git_dir" --work-tree="$HOME" "$@"
}

_ask_user_yes_no() {
    # Prompt user for yes/no input. Returns 0 for yes, 1 for no.
    # Usage: _ask_user_yes_no "Your question?"
    local question="$1"
    local answer
    while true; do
        # Use /dev/tty to ensure prompt goes to terminal, not stdout pipe
        printf "[PROMPT] %s (y/n): " "$question" > /dev/tty
        read -r answer < /dev/tty # Read directly from terminal
        case "$answer" in
            [Yy]* ) return 0;; # Yes
            [Nn]* ) return 1;; # No
            * ) printf "Please answer yes (y) or no (n).\n" > /dev/tty;;
        esac
    done
}

_backup_files() {
    # Moves listed files from $HOME to a timestamped backup directory.
    # Usage: _backup_files <backup_prefix> <file_list...>
    local backup_prefix="$1"
    shift
    local files_to_backup=("$@") # Capture remaining arguments as files
    local backup_dir
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir=$(eval echo "~/${backup_prefix}_backup_${timestamp}")

    if [ ${#files_to_backup[@]} -eq 0 ]; then
        _log "No files specified for backup."
        return 0 # Not an error if list is empty
    fi

    _log "Creating backup directory: $backup_dir"
    if ! mkdir -p "$backup_dir"; then
        _log "Error: Failed to create backup directory '$backup_dir'. Skipping backup."
        return 1 # Indicate backup failure
    fi

    _log "Backing up conflicting files..."
    local f
    local success=0
    for f in "${files_to_backup[@]}"; do
        local source_path
        source_path=$(eval echo "~/$f") # Expand ~ in source path
        local dest_path="$backup_dir/$f"

        if [ -e "$source_path" ] || [ -L "$source_path" ]; then # Check if file or symlink exists
             # Ensure destination directory exists within backup dir
            if ! mkdir -p "$(dirname "$dest_path")"; then
                 _log "Error: Failed to create subdirectory in backup for '$f'. Skipping."
                 success=1 # Mark as partial failure
                 continue
            fi
             _log "  Moving '$source_path' to '$dest_path'"
            if ! mv "$source_path" "$dest_path"; then
                _log "Error: Failed to move '$source_path'. Skipping."
                success=1 # Mark as partial failure
            fi
        else
            _log "Warning: File '$source_path' listed for backup not found. Skipping."
        fi
    done

    if [ "$success" -eq 0 ]; then
        _log "Backup completed successfully to $backup_dir"
        return 0
    else
        _log "Backup completed with errors. Please check $backup_dir"
        return 1 # Indicate partial or full failure
    fi
}

_parse_conflicts() {
    # Parses conflict list from git checkout stderr. Outputs one file per line.
    # Reads from stdin.
    # Example input line: "        .bashrc"
    grep -E '^\s+' | sed -e 's/^[[:space:]]*//' # Grep lines starting with space, remove leading space
}

_clone_repo() {
    # Clones a repository, trying SSH first and falling back to HTTPS on auth errors.
    # Usage: _clone_repo <repo_type> <ssh_url> <https_url> <bare_path>
    local repo_type="$1"    # e.g., "dotfiles" or "secrets"
    local ssh_url="$2"
    local https_url="$3"
    local bare_path="$4"
    local clone_output
    local clone_exit_code

    if [ -d "$bare_path" ]; then
        _log "$repo_type repository already exists at $bare_path. Skipping clone."
        return 0
    fi

    _log "Attempting to clone $repo_type repository using SSH ($ssh_url)..."
    # Try SSH, capture stderr, prevent script exit on error using || true
    clone_output=$(git clone --bare "$ssh_url" "$bare_path" 2>&1 || true)

    # SSH clone failed, check if it was a permission error
    case "$clone_output" in
        *Permission*denied*|*Could*not*read*from*remote*repository*|*fatal:*Could*not*read*)
            _log "SSH clone failed (Permission Denied / Auth Error)."

            if [ -z "$https_url" ]; then
                 _log "Error: No HTTPS URL provided for $repo_type fallback. Cannot clone."
                 return 1
            fi

             _log "Attempting to clone $repo_type repository using HTTPS ($https_url)..."
            # Try HTTPS, capture stderr, prevent script exit on error
            clone_output=$(git clone --bare "$https_url" "$bare_path" 2>&1 || true)
            clone_exit_code=$?

            if [ "$clone_exit_code" -eq 0 ]; then
                 _log "HTTPS clone successful for $repo_type."
                 # Note: User might be prompted for username/password by git credential helper here
                 return 0 # Success
             else
                 _log "Error: HTTPS clone also failed for $repo_type."
                 printf "Error details:\n%s\n" "$clone_output" >&2
                 return 1 # Both failed
             fi
            ;; # End of SSH auth error case

        *) # SSH failed for a different reason (network, repo not found, etc.)
            _log "Error: SSH clone failed for $repo_type (non-auth error)."
            printf "Error details:\n%s\n" "$clone_output" >&2
            return 1
            ;;
    esac
}


# --- Interactive Checkout Function ---

_interactive_checkout() {
    # Attempts checkout, prompts user on conflict, offers backup.
    # Usage: _interactive_checkout <repo_type> <backup_prefix>
    # repo_type: 'dotfiles' or 'secrets'
    # backup_prefix: e.g., 'dotfiles' or 'secrets' for backup dir name
    local repo_type="$1"
    local backup_prefix="$2"
    local checkout_output
    local conflict_files_list # Array to hold conflict files
    local conflict_file # Loop variable

    _log "Attempting initial checkout for '$repo_type'..."

    # Try checkout without force, capture stderr to check for conflicts
    # We use || true to prevent set -e from exiting if checkout fails
    # We redirect stderr (2) to stdout (1) to capture it in the variable
    checkout_output=$(_git_cmd "$repo_type" checkout 2>&1 || true)

    # Checkout failed, check if it looks like a conflict error
    # Use simple string matching for portability
    case "$checkout_output" in
        *error:*overwritten*|*error:*would*overwrite*)
            _log "Checkout failed due to potential file conflicts:"
            # Print the relevant part of the error for the user
            printf "%s\n" "$checkout_output" | grep -E '^\s+|error:' >&2 # Show error lines on terminal stderr

            # Extract conflicting files into an array (requires bash/zsh for arrays, adapt for POSIX sh)
            # POSIX sh alternative: process line by line or use a simple string list
            # Using a temporary file for POSIX sh compatibility:
            local conflict_tmp_file
            conflict_tmp_file=$(mktemp)
            printf "%s\n" "$checkout_output" | _parse_conflicts > "$conflict_tmp_file"

            # Check if we actually extracted any files
            if [ ! -s "$conflict_tmp_file" ]; then
                _log "Warning: Could not parse conflicting files from output. Proceeding cautiously."
                # Decide how to handle this - maybe just try force checkout or ask generically?
                # Ask generically for now:
                if ! _ask_user_yes_no "Git reported errors. Attempt force checkout anyway?"; then
                    _log "Skipping checkout for '$repo_type'."
                    rm -f "$conflict_tmp_file"
                    return 1
                fi
                 # If yes, proceed to force checkout without backup step
                _log "Proceeding with forced checkout for '$repo_type'..."
                if _git_cmd "$repo_type" checkout -f; then
                    _log "'$repo_type' forced checkout successful."
                    rm -f "$conflict_tmp_file"
                    return 0
                else
                    _log "Error: Forced checkout for '$repo_type' also failed."
                    rm -f "$conflict_tmp_file"
                    return 1
                fi
            fi

            # Ask user about overwriting
            if ! _ask_user_yes_no "Overwrite the conflicting files listed above?"; then
                _log "Skipping checkout for '$repo_type'."
                rm -f "$conflict_tmp_file"
                return 1 # User chose not to overwrite
            fi

            # Ask user about backup
            if _ask_user_yes_no "Back up these files before overwriting?"; then
                # Read files from temp file line by line for POSIX sh compatibility
                local backup_failed=0
                local file_list_for_backup=""
                while IFS= read -r conflict_file; do
                     # Accumulate file list for _backup_files function
                     # Using space separation here; complex names might need better handling
                    file_list_for_backup="$file_list_for_backup $conflict_file"
                done < "$conflict_tmp_file"

                # Call backup function with the accumulated list
                # Need to handle the leading space if file_list_for_backup is not empty
                if [ -n "$file_list_for_backup" ]; then
                    # Pass arguments correctly - using eval might be needed for complex filenames
                    # Or better: loop inside _backup_files reading from the temp file directly
                     # Let's modify _backup_files to read from a file path if given
                    # For now, we pass the list (fragile with spaces/special chars):
                     # shellcheck disable=SC2086 # We intend word splitting here
                    if ! _backup_files "$backup_prefix" $file_list_for_backup; then
                        backup_failed=1
                        # Ask if user wants to proceed even if backup failed
                        if ! _ask_user_yes_no "Backup failed or had errors. Continue with overwrite anyway?"; then
                            _log "Aborting checkout for '$repo_type' due to backup failure."
                            rm -f "$conflict_tmp_file"
                            return 1
                        fi
                    fi
                else
                    _log "No files were parsed for backup."
                fi
            fi
            rm -f "$conflict_tmp_file" # Clean up temp file

            # Proceed with forced checkout
            _log "Proceeding with forced checkout for '$repo_type'..."
            if _git_cmd "$repo_type" checkout -f; then
                _log "'$repo_type' forced checkout successful."
                return 0
            else
                _log "Error: Forced checkout for '$repo_type' also failed."
                return 1
            fi
            ;;
        *)
            # Checkout failed for a different reason (e.g., invalid branch, index issues)
            _log "Error: Checkout for '$repo_type' failed for a non-conflict reason:"
            printf "%s\n" "$checkout_output" >&2 # Print the captured output to stderr
            _log "Please resolve the git issue manually."
            return 1
            ;;
    esac
}

# --- Prerequisites ---
_log "Checking prerequisites..."
command -v git >/dev/null 2>&1 || { _log "Error: git is not installed. Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { _log "Error: curl is not installed. Aborting."; exit 1; }
_log "Prerequisites met."

# --- Clone Repositories (if they don't exist) ---
_log "Setting up repositories..."

if [ ! -d "$DOTFILES_BARE_PATH" ]; then
    _clone_repo "dotfiles" "$DOTFILES_REPO_SSH" "$DOTFILES_REPO_HTTPS" "$DOTFILES_BARE_PATH" || {
        _log "FATAL: Failed to clone dotfiles repository. Aborting."
        exit 1
    }
else
    _log "Dotfiles repository already exists at $DOTFILES_BARE_PATH."
fi

if [ -n "$SECRETS_REPO" ] && [ ! -d "$SECRETS_BARE_PATH" ]; then
    _log "Cloning secrets repository ($SECRETS_REPO)..."
    # Ensure you have SSH access configured *before* running this script
    git clone --bare "$SECRETS_REPO" "$SECRETS_BARE_PATH" || {
        # Failure is non-fatal here:
        _log "WARNING: Failed to clone secrets repository (tried SSH and HTTPS)."
        _log "         Continuing setup without secrets. Some features may not work."
        # DO NOT exit 1 here if secrets are optional
    }
elif [ -n "$SECRETS_REPO" ]; then
     _log "Secrets repository already exists at $SECRETS_BARE_PATH."
fi

# --- Checkout Dotfiles ---
_log "Checking out dotfiles into $HOME..."
_interactive_checkout "dotfiles" "dotfiles" || _log "Dotfiles checkout skipped or failed."

# --- Checkout Secrets (Optional) ---
if [ -n "$SECRETS_REPO" ] && [ -d "$SECRETS_BARE_PATH" ]; then
    _log "Checking out secrets into $HOME..."
    _interactive_checkout "secrets" "secrets" || _log "Secrets checkout skipped or failed."
fi

# --- Initialize Submodules ---
_log "Initializing/updating submodules (e.g., nvim)..."
_git_cmd dotfiles submodule init
_git_cmd dotfiles submodule update --init --recursive # --remote might be useful on subsequent runs

# --- Configure Local Git Settings ---
_log "Configuring dotfiles git repository (showUntrackedFiles=no)..."
# Check if the config exists before setting it
if ! _git_cmd dotfiles config --local --get status.showUntrackedFiles > /dev/null 2>&1; then
    _git_cmd dotfiles config --local status.showUntrackedFiles no
    _log "Set status.showUntrackedFiles=no."
else
    _log "status.showUntrackedFiles already configured."
fi


# --- Fish Plugin Installation ---
_log "Checking for Fish shell..."
if command -v fish >/dev/null 2>&1; then
    _log "Fish shell found. Setting up Fisher plugins..."

    FISH_CONFIG_DIR=$(eval echo "~/.config/fish")
    FISH_PLUGINS_FILE="$FISH_CONFIG_DIR/fish_plugins"
    FISHER_FUNC_FILE="$FISH_CONFIG_DIR/functions/fisher.fish"
    FISHER_COMP_FILE="$FISH_CONFIG_DIR/completions/fisher.fish" # Define completion file path too

    # 1. Ensure the Fisher function file itself exists.
    if [ ! -f "$FISHER_FUNC_FILE" ]; then
        _log "Fisher function file not found. Installing Fisher core..."
        # Create necessary directories if they don't exist
        mkdir -p "$(dirname "$FISHER_FUNC_FILE")"    # Use dirname for robustness
        mkdir -p "$(dirname "$FISHER_COMP_FILE")"
        # Download fisher.fish and completions directly
        curl -Lo "$FISHER_FUNC_FILE" --create-dirs https://git.io/fisher
        curl -Lo "$FISHER_COMP_FILE" --create-dirs https://raw.githubusercontent.com/jorgebucaran/fisher/main/completions/fisher.fish
        _log "Fisher core installed."
    else
        _log "Fisher function file already exists."
    fi

    # 2. Run `fisher update` in a clean environment
    if [ -f "$FISH_PLUGINS_FILE" ]; then
        _log "Running 'fisher update' to install plugins from $FISH_PLUGINS_FILE..."
        # Use --no-config to avoid loading user's potentially interfering config.fish
        # Manually source the downloaded fisher function first.
        # Ensure path expansion and quoting are correct.
        fish_command="source \"$FISHER_FUNC_FILE\"; fisher update"

        _log "Executing: fish --no-config -c '$fish_command'" # Log the command for debugging

        # Execute fisher update in the clean, non-interactive fish shell
        if fish --no-config -c "$fish_command"; then
             _log "Fisher update completed successfully."

            # --- Configure Tide Automatically ---
            # Now that fisher update succeeded, Tide should be installed.
            # We can run its configuration command.
            _log "Configuring Tide prompt automatically..."
            # Define the command exactly as you provided it
            tide_config_command="tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Dotted --prompt_connection_andor_frame_color=Light --prompt_spacing=Compact --icons='Few icons' --transient=No"

            # Execute this using a normal fish -c.
            # Fish should now be able to find the 'tide' function via autoloading
            # or potentially via your config.fish if it's sourced by default.
            # We expect this to succeed now that plugins are installed.
            if fish -c "$tide_config_command"; then
                _log "Tide auto-configuration successful."
            else
                tide_exit_code=$?
                _log "Warning: Tide auto-configuration command failed with exit code $tide_exit_code."
                _log "         The command was: $tide_config_command"
                _log "         You may need to run 'tide configure' manually in Fish later."
            fi
            # --- End Tide Configuration ---
        else
             fisher_exit_code=$? # Capture exit code for logging
             _log "Error: Fisher update failed with exit code $fisher_exit_code. Check Fish output above for details."
             # Consider adding more specific error checking here if needed
             # exit 1 # Optional: Exit if Fisher setup is critical
        fi
    else
        _log "Warning: $FISH_PLUGINS_FILE not found. Skipping 'fisher update'."
    fi
else
    _log "Fish shell not found. Skipping Fisher plugin installation."
fi

mkdir -p $(eval echo "~/notes/vault-13/")

# --- Final Steps ---
# Check if private.fish exists and mention potential pass errors
PRIVATE_FISH_FILE=$(eval echo "~/.config/fish/private.fish") # Adjust path if needed
if [ -f "$PRIVATE_FISH_FILE" ]; then
    _log "---"
    _log "IMPORTANT: Your Fish configuration includes 'private.fish' which uses 'pass'."
    _log "If 'pass' (the password store) is not yet installed and fully configured"
    _log "with your GPG key and the necessary secrets (e.g., api/tokens/openai),"
    _log "you WILL likely see 'Error: ... is not in the password store.' messages"
    _log "when you start Fish for the first time after this setup."
    _log " "
    _log "REQUIRED MANUAL STEPS:"
    _log "  1. Install 'pass' if you haven't (e.g., 'sudo apt install pass', 'brew install pass')."
    _log "  2. Ensure your GPG key is set up correctly."
    _log "  3. Initialize your password store if needed ('pass init YOUR_GPG_KEY_ID')."
    _log "  4. Add the required secrets ('pass insert api/tokens/openai', etc.)."
    _log "  The errors should disappear once 'pass' is functional and contains the keys."
    _log "---"
fi

_log "Please restart your shell or run 'exec fish' (if applicable) for all changes to take effect."

exit 0
