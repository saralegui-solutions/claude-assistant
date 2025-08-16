#!/bin/bash

# Auto-Checkpoint System for Claude Code
# Creates automatic savepoints for conversation recovery

set -euo pipefail

# Configuration
CHECKPOINT_DIR="${HOME}/.claude/checkpoints"
MAX_CHECKPOINTS=10
LOG_FILE="/tmp/claude-checkpoint.log"
TRIGGER="${1:-manual}"
METADATA_FILE="/tmp/claude-session-metadata.json"

# Create checkpoint directory if not exists
mkdir -p "$CHECKPOINT_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to get current session ID
get_session_id() {
    # Try to get from environment or generate
    if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
        echo "$CLAUDE_SESSION_ID"
    else
        # Generate based on current time and process
        echo "session-$(date +%s)-$$"
    fi
}

# Function to create checkpoint
create_checkpoint() {
    local session_id=$(get_session_id)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local checkpoint_name="checkpoint-${session_id}-${timestamp}-${TRIGGER}"
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_name}"
    
    log_message "Creating checkpoint: ${checkpoint_name}"
    
    # Create checkpoint directory
    mkdir -p "$checkpoint_path"
    
    # Save conversation history if available
    if [ -d "${HOME}/.claude/conversations" ]; then
        # Find most recent conversation file
        local latest_conv=$(ls -t "${HOME}/.claude/conversations"/*.json 2>/dev/null | head -1)
        if [ -n "$latest_conv" ]; then
            cp "$latest_conv" "${checkpoint_path}/conversation.json"
            log_message "Saved conversation history"
        fi
    fi
    
    # Save current rate limits
    if [ -f "/tmp/claude-rate-limits.json" ]; then
        cp "/tmp/claude-rate-limits.json" "${checkpoint_path}/rate-limits.json"
    fi
    
    # Save session metadata
    cat > "${checkpoint_path}/metadata.json" <<EOF
{
    "session_id": "${session_id}",
    "timestamp": "${timestamp}",
    "trigger": "${TRIGGER}",
    "created_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "working_directory": "$(pwd)",
    "user": "$(whoami)",
    "hostname": "$(hostname)"
}
EOF
    
    # Save current project state
    if [ -d ".git" ]; then
        git status --short > "${checkpoint_path}/git-status.txt" 2>/dev/null || true
        git diff > "${checkpoint_path}/git-diff.patch" 2>/dev/null || true
    fi
    
    # Save list of open files if tracked
    if [ -f "/tmp/claude-open-files.txt" ]; then
        cp "/tmp/claude-open-files.txt" "${checkpoint_path}/open-files.txt"
    fi
    
    # Create recovery script
    cat > "${checkpoint_path}/recover.sh" <<'EOF'
#!/bin/bash
# Recovery script for this checkpoint

echo "Recovering from checkpoint..."

# Restore conversation if Claude Code supports it
if [ -f "conversation.json" ]; then
    echo "To restore conversation, use: claude-code --resume conversation.json"
fi

# Show git status at checkpoint time
if [ -f "git-status.txt" ]; then
    echo "Git status at checkpoint:"
    cat git-status.txt
fi

# Apply git patches if needed
if [ -f "git-diff.patch" ] && [ -s "git-diff.patch" ]; then
    echo "Uncommitted changes saved in git-diff.patch"
    echo "To apply: git apply git-diff.patch"
fi

echo "Checkpoint metadata:"
cat metadata.json | jq '.' 2>/dev/null || cat metadata.json

echo "Recovery information complete."
EOF
    chmod +x "${checkpoint_path}/recover.sh"
    
    log_message "Checkpoint created successfully: ${checkpoint_path}"
    echo "✓ Checkpoint saved: ${checkpoint_name}" >&2
    
    # Clean up old checkpoints
    cleanup_old_checkpoints
    
    # Return checkpoint path for other scripts
    echo "$checkpoint_path"
}

# Function to cleanup old checkpoints
cleanup_old_checkpoints() {
    local checkpoint_count=$(ls -1 "$CHECKPOINT_DIR" | grep -c "^checkpoint-" || true)
    
    if [ "$checkpoint_count" -gt "$MAX_CHECKPOINTS" ]; then
        local to_remove=$((checkpoint_count - MAX_CHECKPOINTS))
        log_message "Removing $to_remove old checkpoints"
        
        # Remove oldest checkpoints
        ls -1t "$CHECKPOINT_DIR" | grep "^checkpoint-" | tail -n "$to_remove" | while read checkpoint; do
            rm -rf "${CHECKPOINT_DIR}/${checkpoint}"
            log_message "Removed old checkpoint: $checkpoint"
        done
    fi
}

# Function to list checkpoints
list_checkpoints() {
    echo "Available checkpoints:" >&2
    ls -1t "$CHECKPOINT_DIR" 2>/dev/null | grep "^checkpoint-" | head -10 | while read checkpoint; do
        if [ -f "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" ]; then
            local created=$(jq -r '.created_at' "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" 2>/dev/null)
            local trigger=$(jq -r '.trigger' "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" 2>/dev/null)
            echo "  - $checkpoint (${trigger} at ${created})" >&2
        else
            echo "  - $checkpoint" >&2
        fi
    done
}

# Function to recover from checkpoint
recover_checkpoint() {
    local checkpoint_name="${1:-}"
    
    if [ -z "$checkpoint_name" ]; then
        # Use most recent checkpoint
        checkpoint_name=$(ls -1t "$CHECKPOINT_DIR" | grep "^checkpoint-" | head -1)
    fi
    
    if [ -z "$checkpoint_name" ]; then
        echo "No checkpoints available" >&2
        exit 1
    fi
    
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_name}"
    
    if [ ! -d "$checkpoint_path" ]; then
        echo "Checkpoint not found: $checkpoint_name" >&2
        exit 1
    fi
    
    log_message "Recovering from checkpoint: ${checkpoint_name}"
    
    # Execute recovery script
    if [ -x "${checkpoint_path}/recover.sh" ]; then
        cd "$checkpoint_path" && ./recover.sh
    fi
}

# Main execution
case "${TRIGGER}" in
    list)
        list_checkpoints
        ;;
    recover)
        recover_checkpoint "${2:-}"
        ;;
    critical|warning|manual|auto|*)
        create_checkpoint
        ;;
esac

exit 0