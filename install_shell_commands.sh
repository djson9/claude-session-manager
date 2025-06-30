#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALIAS_NAME="claude-session-manager"
ALIAS_CMD="alias $ALIAS_NAME='$SCRIPT_DIR/session_manager.sh'"

install_commands() {
    echo "Installing claude-session-manager command..."
    
    # Check if alias already exists in .zshrc
    if grep -q "alias $ALIAS_NAME=" ~/.zshrc 2>/dev/null; then
        echo "Updating existing alias in ~/.zshrc..."
        # Remove old alias
        sed -i.bak "/alias $ALIAS_NAME=/d" ~/.zshrc
    fi
    
    # Add alias to .zshrc
    echo "" >> ~/.zshrc
    echo "# Claude Session Manager" >> ~/.zshrc
    echo "$ALIAS_CMD" >> ~/.zshrc
    
    echo "✓ Added '$ALIAS_NAME' alias to ~/.zshrc"
    echo ""
    echo "To use the command immediately, run:"
    echo "  source ~/.zshrc"
    echo ""
    echo "Or restart your terminal."
}

uninstall_commands() {
    echo "Removing claude-session-manager command..."
    
    # Remove alias from .zshrc
    if grep -q "alias $ALIAS_NAME=" ~/.zshrc 2>/dev/null; then
        sed -i.bak "/alias $ALIAS_NAME=/d" ~/.zshrc
        sed -i.bak "/# Claude Session Manager/d" ~/.zshrc
        echo "✓ Removed '$ALIAS_NAME' alias from ~/.zshrc"
    else
        echo "Alias not found in ~/.zshrc"
    fi
}

# Main logic
case "$1" in
    uninstall)
        uninstall_commands
        ;;
    *)
        install_commands
        ;;
esac