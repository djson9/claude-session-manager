#!/bin/bash

# Migration script for moving sessions from ~/.claude-sessions to local sessions/ folder

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_DIR="$HOME/.claude-sessions"
NEW_DIR="$SCRIPT_DIR/sessions"

echo "Session Migration Tool"
echo "====================="
echo

if [ ! -d "$OLD_DIR" ]; then
    echo "No sessions found in $OLD_DIR"
    echo "Nothing to migrate."
    exit 0
fi

# Count sessions
SESSION_COUNT=$(find "$OLD_DIR" -maxdepth 1 -type d -name "20*" | wc -l)

if [ "$SESSION_COUNT" -eq 0 ]; then
    echo "No sessions found to migrate."
    exit 0
fi

echo "Found $SESSION_COUNT sessions in $OLD_DIR"
echo
echo "This will move them to: $NEW_DIR"
echo
read -p "Continue with migration? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 0
fi

# Create new directory
mkdir -p "$NEW_DIR"

# Move sessions
echo "Migrating sessions..."
moved=0
for session_dir in "$OLD_DIR"/20*; do
    if [ -d "$session_dir" ]; then
        session_name=$(basename "$session_dir")
        echo "  Moving $session_name..."
        mv "$session_dir" "$NEW_DIR/"
        ((moved++))
    fi
done

echo
echo "Migration complete! Moved $moved sessions."
echo

# Offer to remove old directory
if [ -d "$OLD_DIR" ] && [ -z "$(ls -A "$OLD_DIR")" ]; then
    read -p "Remove empty directory $OLD_DIR? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rmdir "$OLD_DIR"
        echo "Old directory removed."
    fi
fi

echo "Done!"