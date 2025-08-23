# Rate Limit Manager Module

## Overview
The Rate Limit Manager prevents API errors by monitoring usage in real-time and taking proactive measures to avoid hitting rate limits.

## Features
- 🔍 Real-time API usage monitoring
- 📊 Interactive dashboard with visual indicators
- 🛡️ Automatic blocking when approaching limits
- 💾 Smart checkpointing to preserve conversations
- 📈 Context size tracking and optimization
- ⚠️ Multi-level warnings (70% yellow, 90% red)

## Installation

### Via Interactive Installer
```bash
./install-interactive.sh
# Select: [1] Rate Limit Manager
```

### Manual Installation
```bash
./modules/rate-limit-manager/install.sh
```

## Usage

### Dashboard
```bash
dash                    # Quick alias
claude-dashboard        # Full command
ca dashboard           # Via main launcher
```

#### Dashboard Controls
- `q` - Quit
- `r` - Refresh manually
- `c` - Create checkpoint
- `h` - Help
- Auto-refreshes every second

### Checkpointing
```bash
ca checkpoint          # Create checkpoint
ca checkpoint list     # List checkpoints
ca checkpoint restore  # Restore from checkpoint
```

### Context Management
```bash
ca context            # Check current context
ca context analyze    # Detailed analysis
```

## Configuration

### File Location
`~/.claude/config/rate-limit-config.json`

### Configuration Options
```json
{
  "thresholds": {
    "warning": 70,        // Yellow warning threshold
    "critical": 90,       // Red critical threshold
    "auto_block": 95      // Automatic blocking threshold
  },
  "checkpoint": {
    "auto_enable": true,
    "interval_minutes": 30,
    "max_checkpoints": 10,
    "on_warning": true    // Auto checkpoint at warning
  },
  "dashboard": {
    "refresh_rate": 1000,  // Milliseconds
    "show_recommendations": true,
    "sound_alerts": false
  }
}
```

## How It Works

### Monitoring Flow
1. **Pre-execution Check**: Before each Claude operation
2. **Usage Calculation**: Tracks requests, input/output tokens
3. **Threshold Evaluation**: Compares against configured limits
4. **Action Decision**: Warning, checkpoint, or block
5. **Post-execution Update**: Updates metrics after operation

### Visual Indicators
- 🟢 Green (0-69%): Safe operating range
- 🟡 Yellow (70-89%): Caution, approaching limits
- 🔴 Red (90-100%): Critical, immediate action needed

## Troubleshooting

### Dashboard Won't Start
```bash
chmod +x ~/.claude/bin/claude-dashboard
ls -la ~/.claude/config/rate-limit-config.json
```

### Metrics Not Updating
- Check Claude Code is running
- Verify hooks are configured in settings.json
- Restart Claude Code

### False Positives
- Adjust thresholds in config
- Check for rate limit reset time
- Clear old checkpoint data

## Advanced Features

### Custom Hooks
Add to `~/.claude/config/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/rate-limit-monitor.sh"
      }]
    }]
  }
}
```

### Metrics Export
```bash
# Export current metrics
claude-dashboard --export > metrics.json

# Generate report
claude-dashboard --report > report.txt
```

## Module Dependencies
- jq (JSON processing)
- bash 4.0+
- Claude Code settings.json access

## Files Installed
- `~/.claude/bin/claude-dashboard` - Main dashboard script
- `~/.claude/config/rate-limit-config.json` - Configuration
- `~/.claude/hooks/rate-limit-monitor.sh` - Monitoring hook
- `~/.claude/hooks/auto-checkpoint.sh` - Checkpoint manager
- `~/.claude/hooks/context-manager.sh` - Context analyzer
- `~/.claude/data/checkpoints/` - Checkpoint storage

## Best Practices
1. Keep dashboard open during long sessions
2. Create manual checkpoints before complex tasks
3. Monitor context size, not just rate limits
4. Configure auto-checkpoint for safety
5. Adjust thresholds based on your API plan

## Version
Current: 2.0
Compatible with: Claude Code 1.0+