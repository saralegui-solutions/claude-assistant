#!/bin/bash

# Claude Assistant Startup Hook
# This hook runs when Claude Code starts to check for model updates

CLAUDE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
UPDATER_CONFIG="$HOME/.claude-assistant/updater.json"

# Check if updater is configured and enabled
if [ -f "$UPDATER_CONFIG" ]; then
  ENABLED=$(jq -r '.enabled // true' "$UPDATER_CONFIG" 2>/dev/null)
  
  if [ "$ENABLED" = "true" ]; then
    # Run update check in background
    if [ -f "$CLAUDE_DIR/check-updates.js" ]; then
      (
        cd "$CLAUDE_DIR"
        node check-updates.js --silent 2>/dev/null
      ) &
    fi
  fi
fi

# Check for any pending updates notification
UPDATE_NOTICE="$HOME/.claude-assistant/.update-notice"
if [ -f "$UPDATE_NOTICE" ]; then
  cat "$UPDATE_NOTICE"
  rm "$UPDATE_NOTICE"
fi