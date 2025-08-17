#!/bin/bash

# Rate Limit Dashboard for Claude Code
# Displays real-time rate limit status and usage metrics

set -euo pipefail

# Configuration
API_KEY="${ANTHROPIC_API_KEY:-}"
CACHE_FILE="/tmp/claude-rate-limits.json"
METRICS_FILE="/tmp/claude-context-metrics.json"
LOG_FILE="/tmp/claude-rate-monitor.log"
CHECKPOINT_DIR="${HOME}/.claude/checkpoints"
REFRESH_INTERVAL="${1:-5}"  # Default 5 seconds

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to draw a progress bar
draw_progress_bar() {
    local percentage=$1
    local width=30
    local filled=$(( percentage * width / 100 ))
    local empty=$(( width - filled ))
    
    # Choose color based on percentage
    local color="$GREEN"
    if [ "$percentage" -ge 80 ]; then
        color="$RED"
    elif [ "$percentage" -ge 60 ]; then
        color="$YELLOW"
    fi
    
    printf "${color}"
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${NC} %3d%%" "$percentage"
}

# Function to format number with commas
format_number() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Function to display dashboard header
display_header() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         Claude Code Rate Limit & Context Dashboard          ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to fetch current rate limits
fetch_rate_limits() {
    if [ -z "$API_KEY" ]; then
        return 1
    fi
    
    # Make minimal API call to get rate limit headers
    curl -s -i \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -X POST https://api.anthropic.com/v1/messages \
        -d '{"model":"claude-3-haiku-20240307","messages":[{"role":"user","content":"test"}],"max_tokens":1}' \
        2>/dev/null | head -30 > /tmp/claude-api-response.tmp
    
    # Extract and save rate limit information
    local requests_limit=$(grep -i "anthropic-ratelimit-requests-limit:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local requests_remaining=$(grep -i "anthropic-ratelimit-requests-remaining:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local input_limit=$(grep -i "anthropic-ratelimit-input-tokens-limit:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local input_remaining=$(grep -i "anthropic-ratelimit-input-tokens-remaining:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local output_limit=$(grep -i "anthropic-ratelimit-output-tokens-limit:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local output_remaining=$(grep -i "anthropic-ratelimit-output-tokens-remaining:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    local reset_time=$(grep -i "anthropic-ratelimit-requests-reset:" /tmp/claude-api-response.tmp | awk '{print $2}' | tr -d '\r')
    
    # Calculate usage
    local requests_used=0
    local input_used=0
    local output_used=0
    
    if [ -n "$requests_limit" ] && [ -n "$requests_remaining" ] && [ "$requests_limit" != "" ] && [ "$requests_remaining" != "" ]; then
        requests_used=$((requests_limit - requests_remaining))
    fi
    if [ -n "$input_limit" ] && [ -n "$input_remaining" ] && [ "$input_limit" != "" ] && [ "$input_remaining" != "" ]; then
        input_used=$((input_limit - input_remaining))
    fi
    if [ -n "$output_limit" ] && [ -n "$output_remaining" ] && [ "$output_limit" != "" ] && [ "$output_remaining" != "" ]; then
        output_used=$((output_limit - output_remaining))
    fi
    
    # Save to cache
    cat > "$CACHE_FILE" <<EOF
{
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "requests": {
        "limit": ${requests_limit:-0},
        "remaining": ${requests_remaining:-0},
        "used": ${requests_used}
    },
    "input_tokens": {
        "limit": ${input_limit:-0},
        "remaining": ${input_remaining:-0},
        "used": ${input_used}
    },
    "output_tokens": {
        "limit": ${output_limit:-0},
        "remaining": ${output_remaining:-0},
        "used": ${output_used}
    },
    "reset_time": "${reset_time:-unknown}"
}
EOF
    
    rm -f /tmp/claude-api-response.tmp
}

# Function to display rate limits
display_rate_limits() {
    echo -e "${BOLD}${BLUE}📊 API Rate Limits${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ ! -f "$CACHE_FILE" ]; then
        echo -e "${YELLOW}No rate limit data available. Fetching...${NC}"
        fetch_rate_limits
    fi
    
    if [ -f "$CACHE_FILE" ]; then
        local requests_limit=$(jq -r '.requests.limit // 0' "$CACHE_FILE")
        local requests_remaining=$(jq -r '.requests.remaining // 0' "$CACHE_FILE")
        local requests_used=$(jq -r '.requests.used // 0' "$CACHE_FILE")
        local input_limit=$(jq -r '.input_tokens.limit // 0' "$CACHE_FILE")
        local input_remaining=$(jq -r '.input_tokens.remaining // 0' "$CACHE_FILE")
        local input_used=$(jq -r '.input_tokens.used // 0' "$CACHE_FILE")
        local output_limit=$(jq -r '.output_tokens.limit // 0' "$CACHE_FILE")
        local output_remaining=$(jq -r '.output_tokens.remaining // 0' "$CACHE_FILE")
        local output_used=$(jq -r '.output_tokens.used // 0' "$CACHE_FILE")
        local reset_time=$(jq -r '.reset_time // "unknown"' "$CACHE_FILE")
        
        # Calculate percentages
        local requests_pct=0
        local input_pct=0
        local output_pct=0
        
        [ "$requests_limit" != "null" ] && [ "$requests_limit" -gt 0 ] && requests_pct=$((requests_used * 100 / requests_limit))
        [ "$input_limit" != "null" ] && [ "$input_limit" -gt 0 ] && input_pct=$((input_used * 100 / input_limit))
        [ "$output_limit" != "null" ] && [ "$output_limit" -gt 0 ] && output_pct=$((output_used * 100 / output_limit))
        
        echo ""
        echo -e "${BOLD}Requests:${NC}"
        printf "  Used: %s / %s  " "$(format_number $requests_used)" "$(format_number $requests_limit)"
        draw_progress_bar "$requests_pct"
        echo ""
        
        echo -e "${BOLD}Input Tokens:${NC}"
        printf "  Used: %s / %s  " "$(format_number $input_used)" "$(format_number $input_limit)"
        draw_progress_bar "$input_pct"
        echo ""
        
        echo -e "${BOLD}Output Tokens:${NC}"
        printf "  Used: %s / %s  " "$(format_number $output_used)" "$(format_number $output_limit)"
        draw_progress_bar "$output_pct"
        echo ""
        
        echo -e "${BOLD}Reset Time:${NC} $reset_time"
    else
        echo -e "${RED}Unable to fetch rate limit data. Check API key.${NC}"
    fi
}

# Function to display context metrics
display_context_metrics() {
    echo ""
    echo -e "${BOLD}${BLUE}📝 Context Metrics${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ -f "$METRICS_FILE" ]; then
        local context_tokens=$(jq -r '.estimated_context_tokens // 0' "$METRICS_FILE")
        local usage_tokens=$(jq -r '.estimated_usage_tokens // 0' "$METRICS_FILE")
        local approaching=$(jq -r '.approaching_limit // false' "$METRICS_FILE")
        local suggest_compact=$(jq -r '.suggest_compact // false' "$METRICS_FILE")
        
        echo ""
        echo -e "${BOLD}Estimated Context:${NC} $(format_number $context_tokens) tokens"
        echo -e "${BOLD}Estimated Usage:${NC} $(format_number $usage_tokens) tokens"
        
        if [ "$suggest_compact" = "true" ]; then
            echo -e "${YELLOW}⚠️  Context compaction recommended${NC}"
        elif [ "$approaching" = "true" ]; then
            echo -e "${YELLOW}⚠️  Approaching context limits${NC}"
        else
            echo -e "${GREEN}✓ Context usage normal${NC}"
        fi
    else
        echo -e "${YELLOW}No context metrics available${NC}"
    fi
}

# Function to display checkpoints
display_checkpoints() {
    echo ""
    echo -e "${BOLD}${BLUE}💾 Recent Checkpoints${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ -d "$CHECKPOINT_DIR" ]; then
        local count=0
        echo ""
        ls -1t "$CHECKPOINT_DIR" 2>/dev/null | grep "^checkpoint-" | head -5 | while read checkpoint; do
            if [ -f "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" ]; then
                local created=$(jq -r '.created_at' "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" 2>/dev/null | cut -d'T' -f2 | cut -d'Z' -f1)
                local trigger=$(jq -r '.trigger' "${CHECKPOINT_DIR}/${checkpoint}/metadata.json" 2>/dev/null)
                echo -e "  • ${trigger} at ${created}"
                count=$((count + 1))
            fi
        done
        
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}  No checkpoints found${NC}"
        fi
    else
        echo -e "${YELLOW}  Checkpoint directory not found${NC}"
    fi
}

# Function to display recommendations
display_recommendations() {
    echo ""
    echo -e "${BOLD}${BLUE}💡 Recommendations${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ -f "$CACHE_FILE" ]; then
        local requests_limit=$(jq -r '.requests.limit // 0' "$CACHE_FILE")
        local requests_used=$(jq -r '.requests.used // 0' "$CACHE_FILE")
        local requests_pct=0
        [ "$requests_limit" != "null" ] && [ "$requests_limit" -gt 0 ] && requests_pct=$((requests_used * 100 / requests_limit))
        
        if [ "$requests_pct" -ge 80 ]; then
            echo -e "  ${RED}• Critical: Rate limits nearly exhausted!${NC}"
            echo -e "  ${RED}• Wait for reset or reduce request frequency${NC}"
        elif [ "$requests_pct" -ge 60 ]; then
            echo -e "  ${YELLOW}• Warning: Moderate rate limit usage${NC}"
            echo -e "  ${YELLOW}• Consider creating a checkpoint${NC}"
        else
            echo -e "  ${GREEN}• Rate limits healthy${NC}"
        fi
    fi
    
    if [ -f "/tmp/claude-suggest-compact" ]; then
        echo -e "  ${YELLOW}• Run /compact to optimize context${NC}"
    fi
}

# Function to display footer
display_footer() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Commands:${NC} [q]uit | [r]efresh | [c]heckpoint | [h]elp"
    echo -e "Auto-refresh: ${REFRESH_INTERVAL}s | Last update: $(date '+%H:%M:%S')"
}

# Function to show help
show_help() {
    clear
    echo -e "${BOLD}${CYAN}Rate Limit Dashboard Help${NC}"
    echo ""
    echo "This dashboard monitors your Claude API rate limits and context usage."
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  q - Quit the dashboard"
    echo "  r - Refresh data immediately"
    echo "  c - Create a manual checkpoint"
    echo "  h - Show this help message"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  $0 [refresh_interval]"
    echo ""
    echo "  refresh_interval: Seconds between updates (default: 5)"
    echo ""
    echo "Press any key to return to dashboard..."
    read -n 1 -s
}

# Function to create manual checkpoint
create_manual_checkpoint() {
    echo ""
    echo -e "${CYAN}Creating manual checkpoint...${NC}"
    if [ -x "${HOME}/.claude/hooks/auto-checkpoint.sh" ]; then
        "${HOME}/.claude/hooks/auto-checkpoint.sh" "manual"
        echo -e "${GREEN}✓ Checkpoint created${NC}"
    else
        echo -e "${RED}Checkpoint script not found${NC}"
    fi
    sleep 2
}

# Main dashboard loop
main_loop() {
    while true; do
        display_header
        display_rate_limits
        display_context_metrics
        display_checkpoints
        display_recommendations
        display_footer
        
        # Wait for input with timeout
        if read -t "$REFRESH_INTERVAL" -n 1 key; then
            case "$key" in
                q|Q)
                    echo ""
                    echo "Exiting dashboard..."
                    exit 0
                    ;;
                r|R)
                    fetch_rate_limits
                    ;;
                c|C)
                    create_manual_checkpoint
                    ;;
                h|H)
                    show_help
                    ;;
            esac
        fi
        
        # Auto-refresh
        fetch_rate_limits
    done
}

# Check for dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq (or appropriate for your system)"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}Warning: ANTHROPIC_API_KEY not set${NC}"
    echo "Some features will be limited without an API key."
    echo ""
    echo "Press any key to continue..."
    read -n 1 -s
fi

# Start dashboard
main_loop