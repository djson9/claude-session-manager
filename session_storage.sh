#!/bin/bash

# Session storage directory - use the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="$SCRIPT_DIR/sessions"

# Initialize sessions directory
init_sessions_dir() {
    mkdir -p "$SESSIONS_DIR"
}

# Save a session with metadata
save_session() {
    local session_file="$1"
    local session_name="$2"
    
    if [ -z "$session_file" ] || [ -z "$session_name" ]; then
        echo "Error: Both session file and name are required"
        return 1
    fi
    
    if [ ! -f "$session_file" ]; then
        echo "Error: Session file not found: $session_file"
        return 1
    fi
    
    # Create safe filename from session name
    local safe_name=$(echo "$session_name" | tr ' ' '_' | tr -cd '[:alnum:]._-')
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local session_id="${timestamp}_${safe_name}"
    
    # Create session directory
    local session_dir="$SESSIONS_DIR/$session_id"
    mkdir -p "$session_dir"
    
    # Copy session file
    cp "$session_file" "$session_dir/session.jsonl"
    
    # Create metadata file
    cat > "$session_dir/metadata.json" << EOF
{
    "name": "$session_name",
    "id": "$session_id",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "file": "session.jsonl"
}
EOF
    
    echo "Session saved: $session_id"
    echo "$session_dir"
}

# List all saved sessions
list_sessions() {
    local sessions=()
    
    if [ ! -d "$SESSIONS_DIR" ]; then
        return
    fi
    
    for session_dir in "$SESSIONS_DIR"/*; do
        if [ -d "$session_dir" ] && [ -f "$session_dir/metadata.json" ]; then
            sessions+=("$session_dir")
        fi
    done
    
    # Sort by timestamp (newest first)
    printf '%s\n' "${sessions[@]}" | sort -r
}

# Get session metadata
get_session_metadata() {
    local session_dir="$1"
    local metadata_file="$session_dir/metadata.json"
    
    if [ -f "$metadata_file" ]; then
        cat "$metadata_file"
    fi
}

# Get session file path
get_session_file() {
    local session_dir="$1"
    echo "$session_dir/session.jsonl"
}

# Export functions for use in other scripts
export -f init_sessions_dir
export -f save_session
export -f list_sessions
export -f get_session_metadata
export -f get_session_file