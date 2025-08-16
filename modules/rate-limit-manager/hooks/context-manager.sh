#!/bin/bash

# Context Manager for Claude Code
# Monitors and manages context to prevent token limit issues

set -euo pipefail

# Configuration
LOG_FILE="/tmp/claude-context-manager.log"
METRICS_FILE="/tmp/claude-context-metrics.json"
SUGGEST_COMPACT_FILE="/tmp/claude-suggest-compact"
CONFIG_FILE="${HOME}/.claude/rate-limit-config.json"

# Default thresholds
TOKEN_WARNING_THRESHOLD=150000  # Tokens before warning
TOKEN_COMPACT_THRESHOLD=180000  # Tokens before suggesting compact
MAX_CONTEXT_SIZE=200000  # Maximum context size estimate

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to estimate token count (rough approximation)
estimate_tokens() {
    local text="$1"
    # Rough estimate: 1 token ≈ 4 characters
    echo $(( ${#text} / 4 ))
}

# Function to analyze context usage
analyze_context() {
    local hook_input="${1:-}"
    
    # Try to get context size from hook input if available
    local context_size=0
    
    if [ -n "$hook_input" ]; then
        # Parse hook input for context information
        context_size=$(echo "$hook_input" | jq -r '.context_size // 0' 2>/dev/null || echo "0")
    fi
    
    # Check rate limits cache for token usage
    if [ -f "/tmp/claude-rate-limits.json" ]; then
        local input_remaining=$(jq -r '.input_tokens.remaining // 400000' "/tmp/claude-rate-limits.json")
        local input_limit=$(jq -r '.input_tokens.limit // 400000' "/tmp/claude-rate-limits.json")
        local estimated_usage=$((input_limit - input_remaining))
        
        # Store metrics
        cat > "$METRICS_FILE" <<EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "estimated_context_tokens": ${context_size},
    "estimated_usage_tokens": ${estimated_usage},
    "input_tokens_remaining": ${input_remaining},
    "input_tokens_limit": ${input_limit},
    "approaching_limit": $([ "$estimated_usage" -gt "$TOKEN_WARNING_THRESHOLD" ] && echo "true" || echo "false"),
    "suggest_compact": $([ "$estimated_usage" -gt "$TOKEN_COMPACT_THRESHOLD" ] && echo "true" || echo "false")
}
EOF
        
        # Check if we should suggest compaction
        if [ "$estimated_usage" -gt "$TOKEN_COMPACT_THRESHOLD" ]; then
            log_message "Context usage high: ${estimated_usage} tokens. Suggesting compact."
            echo '{"suggest_compact": true, "reason": "high_token_usage", "usage": '${estimated_usage}'}' > "$SUGGEST_COMPACT_FILE"
            echo "📊 Context usage is high (~${estimated_usage} tokens). Consider using /compact to optimize." >&2
        elif [ "$estimated_usage" -gt "$TOKEN_WARNING_THRESHOLD" ]; then
            log_message "Context usage warning: ${estimated_usage} tokens"
            echo "⚠️  Context usage approaching limits (~${estimated_usage} tokens)" >&2
        fi
    fi
}

# Function to suggest context optimization
suggest_optimizations() {
    echo "Context Optimization Suggestions:" >&2
    echo "1. Use /compact to compress conversation history" >&2
    echo "2. Close unnecessary files with /close" >&2
    echo "3. Clear old tool outputs if not needed" >&2
    echo "4. Start a new conversation for unrelated tasks" >&2
    echo "5. Use checkpoints to save progress" >&2
}

# Function to auto-trigger compact
auto_compact() {
    local force="${1:-false}"
    
    if [ -f "$SUGGEST_COMPACT_FILE" ] || [ "$force" = "true" ]; then
        log_message "Auto-compact triggered"
        
        # Create checkpoint before compact
        if [ -x "${HOME}/.claude/hooks/auto-checkpoint.sh" ]; then
            "${HOME}/.claude/hooks/auto-checkpoint.sh" "pre-compact"
        fi
        
        # Signal Claude Code to compact (this would need Claude Code support)
        echo '{"action": "compact", "triggered_by": "context-manager"}' > /tmp/claude-compact-request
        
        # Remove suggestion file
        rm -f "$SUGGEST_COMPACT_FILE"
        
        echo "✓ Context compaction initiated" >&2
    fi
}

# Function to monitor file operations
track_file_operations() {
    local operation="${1:-}"
    local file_path="${2:-}"
    
    case "$operation" in
        open)
            echo "$file_path" >> /tmp/claude-open-files.txt
            log_message "File opened: $file_path"
            ;;
        close)
            grep -v "^${file_path}$" /tmp/claude-open-files.txt > /tmp/claude-open-files.tmp 2>/dev/null || true
            mv /tmp/claude-open-files.tmp /tmp/claude-open-files.txt 2>/dev/null || true
            log_message "File closed: $file_path"
            ;;
        list)
            if [ -f "/tmp/claude-open-files.txt" ]; then
                echo "Currently open files:" >&2
                cat /tmp/claude-open-files.txt >&2
            fi
            ;;
    esac
}

# Load custom configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    TOKEN_WARNING_THRESHOLD=$(jq -r '.token_warning_threshold // 150000' "$CONFIG_FILE")
    TOKEN_COMPACT_THRESHOLD=$(jq -r '.token_compact_threshold // 180000' "$CONFIG_FILE")
    MAX_CONTEXT_SIZE=$(jq -r '.max_context_size // 200000' "$CONFIG_FILE")
fi

# Main execution
COMMAND="${1:-analyze}"
shift || true

case "$COMMAND" in
    analyze)
        analyze_context "$@"
        ;;
    compact)
        auto_compact "$@"
        ;;
    optimize)
        suggest_optimizations
        ;;
    track)
        track_file_operations "$@"
        ;;
    status)
        if [ -f "$METRICS_FILE" ]; then
            echo "Context Status:" >&2
            jq '.' "$METRICS_FILE" >&2
        else
            echo "No context metrics available" >&2
        fi
        ;;
    *)
        # Hook input
        analyze_context "$COMMAND"
        ;;
esac

exit 0