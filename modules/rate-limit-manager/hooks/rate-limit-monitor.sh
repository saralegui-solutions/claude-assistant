#!/bin/bash

# Rate Limit Monitor for Claude Code
# Monitors API rate limits and triggers warnings/actions

set -euo pipefail

# Configuration
API_KEY="${ANTHROPIC_API_KEY:-}"
CACHE_FILE="/tmp/claude-rate-limits.json"
CONFIG_FILE="${HOME}/.claude/rate-limit-config.json"
LOG_FILE="/tmp/claude-rate-monitor.log"
HOOK_INPUT="${1:-}"

# Default thresholds (can be overridden by config)
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=95
AUTO_COMPACT_THRESHOLD=75

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check rate limits
check_rate_limits() {
    if [ -z "$API_KEY" ]; then
        log_message "ERROR: ANTHROPIC_API_KEY not set"
        exit 0  # Don't block operations if key not set
    fi
    
    # Make minimal API call to get rate limit headers
    local response
    response=$(curl -s -i \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -X POST https://api.anthropic.com/v1/messages \
        -d '{"model":"claude-3-haiku-20240307","messages":[{"role":"user","content":"test"}],"max_tokens":1}' \
        2>/dev/null | head -30)
    
    # Extract rate limit information
    local requests_limit=$(echo "$response" | grep -i "anthropic-ratelimit-requests-limit:" | awk '{print $2}' | tr -d '\r')
    local requests_remaining=$(echo "$response" | grep -i "anthropic-ratelimit-requests-remaining:" | awk '{print $2}' | tr -d '\r')
    local input_limit=$(echo "$response" | grep -i "anthropic-ratelimit-input-tokens-limit:" | awk '{print $2}' | tr -d '\r')
    local input_remaining=$(echo "$response" | grep -i "anthropic-ratelimit-input-tokens-remaining:" | awk '{print $2}' | tr -d '\r')
    local output_limit=$(echo "$response" | grep -i "anthropic-ratelimit-output-tokens-limit:" | awk '{print $2}' | tr -d '\r')
    local output_remaining=$(echo "$response" | grep -i "anthropic-ratelimit-output-tokens-remaining:" | awk '{print $2}' | tr -d '\r')
    local reset_time=$(echo "$response" | grep -i "anthropic-ratelimit-requests-reset:" | awk '{print $2}' | tr -d '\r')
    
    # Calculate usage percentages
    local requests_used_pct=0
    local input_used_pct=0
    local output_used_pct=0
    
    if [ -n "$requests_limit" ] && [ -n "$requests_remaining" ] && [ "$requests_limit" -gt 0 ]; then
        requests_used_pct=$(( (requests_limit - requests_remaining) * 100 / requests_limit ))
    fi
    
    if [ -n "$input_limit" ] && [ -n "$input_remaining" ] && [ "$input_limit" -gt 0 ]; then
        input_used_pct=$(( (input_limit - input_remaining) * 100 / input_limit ))
    fi
    
    if [ -n "$output_limit" ] && [ -n "$output_remaining" ] && [ "$output_limit" -gt 0 ]; then
        output_used_pct=$(( (output_limit - output_remaining) * 100 / output_limit ))
    fi
    
    # Store metrics in cache file
    cat > "$CACHE_FILE" <<EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "requests": {
        "limit": ${requests_limit:-0},
        "remaining": ${requests_remaining:-0},
        "used_percentage": ${requests_used_pct}
    },
    "input_tokens": {
        "limit": ${input_limit:-0},
        "remaining": ${input_remaining:-0},
        "used_percentage": ${input_used_pct}
    },
    "output_tokens": {
        "limit": ${output_limit:-0},
        "remaining": ${output_remaining:-0},
        "used_percentage": ${output_used_pct}
    },
    "reset_time": "${reset_time:-unknown}",
    "max_usage_percentage": $(( requests_used_pct > input_used_pct ? (requests_used_pct > output_used_pct ? requests_used_pct : output_used_pct) : (input_used_pct > output_used_pct ? input_used_pct : output_used_pct) ))
}
EOF
    
    # Check thresholds and take action
    local max_usage=$(( requests_used_pct > input_used_pct ? (requests_used_pct > output_used_pct ? requests_used_pct : output_used_pct) : (input_used_pct > output_used_pct ? input_used_pct : output_used_pct) ))
    
    if [ "$max_usage" -ge "$CRITICAL_THRESHOLD" ]; then
        log_message "CRITICAL: Rate limit usage at ${max_usage}%"
        echo "⚠️  CRITICAL: Rate limit usage at ${max_usage}%. Consider pausing operations." >&2
        
        # Trigger auto-checkpoint if available
        if [ -x "${HOME}/.claude/hooks/auto-checkpoint.sh" ]; then
            "${HOME}/.claude/hooks/auto-checkpoint.sh" "critical"
        fi
        
        # Block operation if critical
        echo '{"block": true, "message": "Rate limits critically high. Please wait for reset."}' 
        exit 1
    elif [ "$max_usage" -ge "$WARNING_THRESHOLD" ]; then
        log_message "WARNING: Rate limit usage at ${max_usage}%"
        echo "⚠️  Warning: Rate limit usage at ${max_usage}%" >&2
        
        # Trigger checkpoint at warning level
        if [ -x "${HOME}/.claude/hooks/auto-checkpoint.sh" ]; then
            "${HOME}/.claude/hooks/auto-checkpoint.sh" "warning"
        fi
    elif [ "$max_usage" -ge "$AUTO_COMPACT_THRESHOLD" ]; then
        log_message "INFO: Rate limit usage at ${max_usage}% - considering auto-compact"
        
        # Signal that auto-compact might be beneficial
        echo '{"suggest_compact": true}' > /tmp/claude-suggest-compact
    fi
    
    log_message "Rate check complete: Requests ${requests_used_pct}%, Input ${input_used_pct}%, Output ${output_used_pct}%"
}

# Load custom configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    WARNING_THRESHOLD=$(jq -r '.warning_threshold // 80' "$CONFIG_FILE")
    CRITICAL_THRESHOLD=$(jq -r '.critical_threshold // 95' "$CONFIG_FILE")
    AUTO_COMPACT_THRESHOLD=$(jq -r '.auto_compact_threshold // 75' "$CONFIG_FILE")
fi

# Main execution
case "${HOOK_INPUT}" in
    *PreToolUse*)
        log_message "PreToolUse hook triggered - checking rate limits"
        check_rate_limits
        ;;
    *PostToolUse*)
        log_message "PostToolUse hook triggered - updating metrics"
        check_rate_limits
        ;;
    *UserPromptSubmit*)
        log_message "UserPromptSubmit hook triggered - validating capacity"
        check_rate_limits
        ;;
    *)
        # Direct invocation
        check_rate_limits
        ;;
esac

exit 0