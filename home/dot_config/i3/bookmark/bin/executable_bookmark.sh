#!/bin/bash

# Get tags via Rofi (comma-separated)
# TAGS=$(echo "" | rofi -dmenu -p "Tags (comma-separated):" -theme-str 'listview { lines: 0; }')

SCRIPT_DIR="$HOME/.config/i3/bookmark"
# Get ML suggestions
VENV_PYTHON="${SCRIPT_DIR}/.venv/bin/python"
SUGGEST_TAGS="${SCRIPT_DIR}/bin/suggest_tags.py"

# Create virtual environment if missing
# Create virtual environment if missing
if [ ! -d "${SCRIPT_DIR}/.venv" ]; then
    notify-send "Bookmark Setup" "Creating Python virtual environment..."
    uv venv "${SCRIPT_DIR}/.venv" || {
        notify-send "Bookmark Error" "Failed to create virtual environment"
        exit 1
    }
    source "${SCRIPT_DIR}/.venv/bin/activate"
    uv pip install -r "${SCRIPT_DIR}/requirements.txt" || {
        notify-send "Bookmark Error" "Failed to install dependencies"
        rm -rf "${SCRIPT_DIR}/.venv"
        exit 1
    }
    deactivate
fi

# Get URL from clipboard
URL=$(xclip -o -selection clipboard)

# Validate URL format
if [[ ! "$URL" =~ ^https?:// ]]; then
    notify-send "Bookmark Error" "Clipboard doesn't contain a valid URL!"
    exit 1
fi

# Extract page title
TITLE=$(curl -sL "$URL" | grep -oP '(?<=<title>).*(?=</title>)' | sed 's/[|/]//g' | tr -d '\n')

# Fallback if title extraction fails
if [ -z "$TITLE" ]; then
    TITLE="Untitled-$(date +%s)"
fi

# Get suggested tags
RAW_TAGS=$("$VENV_PYTHON" "$SUGGEST_TAGS" "$URL")
CLEAN_TAGS=$(echo "$RAW_TAGS" | sed 's/,/, /g')

# Show Rofi with suggestions
TAGS=$(echo "$CLEAN_TAGS" | rofi -dmenu -p "Tags:" \
    -theme-str 'listview { lines: 3; }' \
    -filter "$RAW_TAGS" \
    -mesg "Suggested tags: ${CLEAN_TAGS:-none}")

VAULT_PATH="$HOME/notes/vault-13/bookmarks"

# Create filename (sanitize title)
FILENAME=$(echo "$TITLE" | tr ' ' '-' | tr -cd '[:alnum:]-_').md
FULL_PATH="$VAULT_PATH/$FILENAME"

# YAML frontmatter template
cat <<EOF > "$FULL_PATH"
---
title: "$TITLE"
url: "$URL"
date: "$(date +"%Y-%m-%d")"
tags: [${TAGS}]
publish: true
---

# Description
<!-- Add your notes here -->
EOF

# Confirmation
notify-send "Bookmark Saved" "$TITLE → $FILENAME"
