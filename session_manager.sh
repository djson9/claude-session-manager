#!/bin/bash

# Source the session storage functions
# Get the directory where this script is located
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the session storage functions
source "$DIR/session_storage.sh"

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clear screen and show header
show_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Session Manager (Resume)      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
}

# Display menu of saved sessions
show_menu() {
    local sessions=()
    local names=()
    local dates=()
    
    # Get all sessions
    while IFS= read -r session_dir; do
        if [ -n "$session_dir" ]; then
            sessions+=("$session_dir")
            
            # Get metadata
            local metadata=$(get_session_metadata "$session_dir")
            local name=$(echo "$metadata" | grep '"name"' | cut -d'"' -f4)
            local created=$(echo "$metadata" | grep '"created"' | cut -d'"' -f4)
            
            names+=("$name")
            dates+=("$created")
        fi
    done < <(list_sessions)
    
    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}No saved sessions found.${NC}"
        echo
        echo "Save a session in Claude Code using:"
        echo "  /session:save <session-name>"
        echo
        echo "Press any key to exit..."
        read -n 1
        return 1
    fi
    
    echo -e "${GREEN}Available Sessions:${NC}"
    echo
    
    # Display sessions with numbers
    for i in "${!sessions[@]}"; do
        local num=$((i + 1))
        echo -e "${YELLOW}[$num]${NC} ${names[$i]}"
        echo "    Created: ${dates[$i]}"
        echo
    done
    
    echo -e "${YELLOW}[q]${NC} Quit"
    echo
    
    # Get user selection
    echo -n "Select a session (1-${#sessions[@]}) or 'q' to quit: "
    read -r selection
    
    if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
        return 1
    fi
    
    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#sessions[@]} ]; then
        echo -e "${RED}Invalid selection. Press any key to continue...${NC}"
        read -n 1
        return 0
    fi
    
    # Get selected session
    local selected_index=$((selection - 1))
    local selected_session="${sessions[$selected_index]}"
    local selected_name="${names[$selected_index]}"
    
    # Get the metadata for the selected session
    local selected_metadata=$(get_session_metadata "$selected_session")
    
    # Restore the session
    restore_session "$selected_session" "$selected_name" "$selected_metadata"
}

# Restore a saved session using --resume
restore_session() {
    local session_dir="$1"
    local session_name="$2"
    local metadata="$3"
    
    echo
    echo -e "${GREEN}Preparing to restore: $session_name${NC}"
    echo
    
    # Get the session file
    local session_file=$(get_session_file "$session_dir")
    
    if [ ! -f "$session_file" ]; then
        echo -e "${RED}Error: Session file not found${NC}"
        echo "Press any key to continue..."
        read -n 1
        return 1
    fi
    
    # Extract working directory from metadata
    local working_dir=$(echo "$metadata" | grep '"working_directory"' | cut -d'"' -f4)
    
    # Use saved working directory if available, otherwise use current directory
    local parent_dir
    if [ -n "$working_dir" ] && [ -d "$working_dir" ]; then
        parent_dir="$working_dir"
        echo "Using saved working directory: $working_dir"
    else
        # Fallback to current directory logic
        local cwd=$(pwd)
        if [[ "$cwd" == */.claude ]]; then
            parent_dir=$(dirname "$cwd")
        else
            parent_dir="$cwd"
        fi
        echo "Using current directory: $parent_dir"
    fi
    
    # Get project directory path
    local project_dir_name=$(echo "$parent_dir" | sed 's/\//-/g')
    local project_path="$HOME/.claude/projects/$project_dir_name"
    
    # Generate a unique identifier for this restoration
    local restore_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    echo "Creating new Claude session..."
    
    # Change to the target directory and create a new session
    cd "$parent_dir"
    
    # Use claude -p to create a new session with our UUID marker
    echo "echo $restore_uuid" | claude -p >/dev/null 2>&1
    
    # Wait a moment for the session file to be created
    sleep 1
    
    # Find the newly created session file containing our UUID
    echo "Looking for new session file..."
    local new_session_file=""
    for session_file_candidate in "$project_path"/*.jsonl; do
        if [ -f "$session_file_candidate" ] && grep -q "$restore_uuid" "$session_file_candidate" 2>/dev/null; then
            new_session_file="$session_file_candidate"
            break
        fi
    done
    
    if [ -z "$new_session_file" ]; then
        echo -e "${RED}Error: Could not find newly created session${NC}"
        echo "Searched in: $project_path"
        return 1
    fi
    
    echo "Found new session: $(basename "$new_session_file")"
    
    # Replace the contents with our saved session
    echo "Restoring session contents..."
    cp "$session_file" "$new_session_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Session restored successfully${NC}"
        echo
        
        # Extract the session ID from the filename
        local session_id=$(basename "$new_session_file" .jsonl)
        
        # Clear screen and start Claude with --resume
        clear
        
        echo "Starting Claude Code with restored session..."
        echo -e "${GREEN}Session: $session_name${NC}"
        echo
        echo "Use ESC ESC to view conversation history"
        echo
        
        # Start Claude with the resume flag
        claude --resume "$session_id"
        
        # When Claude exits
        echo
        echo "Claude Code has exited."
        
    else
        echo -e "${RED}Error: Failed to restore session${NC}"
        return 1
    fi
    
    # Exit the manager
    exit 0
}

# Main loop
main() {
    # Initialize sessions directory
    init_sessions_dir
    
    while true; do
        show_header
        if ! show_menu; then
            break
        fi
    done
    
    clear
    echo "Goodbye!"
}

# Run main function
main