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
    
    # Restore the session
    restore_session "$selected_session" "$selected_name"
}

# Restore a saved session using --resume
restore_session() {
    local session_dir="$1"
    local session_name="$2"
    
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
    
    # Get the parent directory (remove .claude from path)
    local cwd=$(pwd)
    local parent_dir
    if [[ "$cwd" == */.claude ]]; then
        parent_dir=$(dirname "$cwd")
    else
        parent_dir="$cwd"
    fi
    
    # Get project directory path
    local project_dir_name=$(echo "$parent_dir" | sed 's/\//-/g')
    local project_path="$HOME/.claude/projects/$project_dir_name"
    
    # Create project directory if it doesn't exist
    mkdir -p "$project_path"
    
    # Generate a session ID (use the saved session's ID if available)
    local session_id=$(basename "$session_dir")
    
    # Copy the session file to the project directory with a proper session ID
    local target_session="$project_path/${session_id}.jsonl"
    
    echo "Setting up session for resume..."
    cp "$session_file" "$target_session"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Session staged successfully${NC}"
        echo
        
        # Extract the actual session ID from the file if it has one
        local file_session_id=$(grep -o '"sessionId":"[^"]*"' "$target_session" | head -1 | cut -d'"' -f4)
        
        if [ -n "$file_session_id" ]; then
            echo "Using session ID from file: $file_session_id"
            session_id="$file_session_id"
        else
            echo "Using generated session ID: $session_id"
        fi
        
        # Clear screen and start Claude with --resume
        clear
        cd "$parent_dir"
        
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
        echo -e "${RED}Error: Failed to stage session${NC}"
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