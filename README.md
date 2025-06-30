# Claude Session Manager

A Claude command for Claude Code that allows you to save conversation sessions and fully recall them in a new session through a CLI. 

```
> /session-save is running…

⏺ I'll save your current session. Please provide a name for this session.

> Testing Hello World

⏺ Session saved successfully as "Testing Hello World"
  (20250630_155114_Testing_Hello_World)!
```

Running `claude-session-manager` we see the saved session.
```
╔════════════════════════════════════════╗
║   Claude Session Manager (Resume)      ║
╚════════════════════════════════════════╝

Available Sessions:

[1] Testing Hello World
    Created: 2025-06-30T19:51:14Z

[q] Quit

Select a session (1-1) or 'q' to quit:
```

## Features

- **Save Sessions**: Save your current Claude conversation with a custom name
- **Browse Sessions**: Interactive CLI to view all saved sessions
- **Restore Sessions**: Resume saved conversations with full history visible in Claude's UI. Does not touch existing sessions. Start your restored session under a new session ID.
- **Persistent Storage**: Sessions are saved in the `sessions/` folder within claude-session-manager

## Installation

1. Clone or copy this folder to your workspace.
2. `make install`
3. `make install shell-command` (optional) This will simply add a function in your zshrc that points to the session-manager start script in this folder.
4. `source ~/.zshrc` Source your zshrc or restart your terminal.
5. Restart Claude Code. You now have access to `/save-session [session-name]`.
6. `claude-session-manager` to see your saved sessions.
