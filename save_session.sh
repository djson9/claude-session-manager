#!/bin/bash

# Get the directory where this script is located
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the session storage functions
source "$DIR/session_storage.sh"

# Get the current Claude session file
get_current_session_file() {
    local cwd=$(pwd)
    
    # Handle if we're in a subdirectory like .claude
    local project_dir
    if [[ "$cwd" == */.claude ]]; then
        project_dir=$(dirname "$cwd")
    else
        project_dir="$cwd"
    fi
    
    # Convert path to project directory name format
    local project_name=$(echo "$project_dir" | sed 's/\//-/g')
    local sessions_dir="$HOME/.claude/projects/$project_name"
    
    echo "Looking in project directory: $sessions_dir" >&2
    
    if [ ! -d "$sessions_dir" ]; then
        echo "Error: Project directory not found: $sessions_dir" >&2
        echo "Available project directories:" >&2
        ls $HOME/.claude/projects/ | grep -E "pdf|workspace" >&2
        return 1
    fi
    
    # Get the most recently modified session file
    local latest_session=$(ls -t "$sessions_dir"/*.jsonl 2>/dev/null | head -1)
    
    if [ -z "$latest_session" ]; then
        echo "Error: No session files found in $sessions_dir" >&2
        return 1
    fi
    
    echo "$latest_session"
}

# Main function
main() {
    local session_name="$1"
    
    if [ -z "$session_name" ]; then
        echo "Error: Session name required"
        echo "Usage: $0 <session-name>"
        exit 1
    fi
    
    # Initialize sessions directory
    init_sessions_dir
    
    # Get current session file
    echo "Finding current session file..."
    SESSION_FILE=$(get_current_session_file)
    
    if [ $? -ne 0 ]; then
        echo "Failed to find current session file"
        exit 1
    fi
    
    echo "Current session file: $SESSION_FILE"
    
    # Save the session
    echo "Saving session as '$session_name'..."
    RESULT=$(save_session "$SESSION_FILE" "$session_name")
    
    if [ $? -eq 0 ]; then
        echo "Session saved successfully!"
        echo "$RESULT"
    else
        echo "Failed to save session"
        exit 1
    fi
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi