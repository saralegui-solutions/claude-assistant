# Claude Code Rate Limit Manager

A comprehensive rate limit monitoring and auto-checkpoint system for Claude Code that prevents 500 errors and ensures smooth, uninterrupted AI-assisted development.

## 🚀 Features

- **Real-time Rate Limit Monitoring**: Continuously tracks API usage across requests, input tokens, and output tokens
- **Automatic Checkpointing**: Creates savepoints when approaching limits or at critical moments
- **Context Management**: Monitors token usage and suggests optimization when needed
- **Interactive Dashboard**: Beautiful terminal UI showing live metrics and recommendations
- **Smart Hooks Integration**: Seamlessly integrates with Claude Code's hook system
- **Configurable Thresholds**: Customize warning levels and behavior to your needs

## 📦 Quick Installation

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/claude-rate-limit-manager/main/install.sh | bash
```

### Manual Install

```bash
# Clone or download the package
git clone https://github.com/yourusername/claude-rate-limit-manager.git
cd claude-rate-limit-manager

# Run the installer
./install.sh
```

## 🎯 What Gets Installed

The installer will:

1. Create necessary directories (`~/.claude/hooks`, `~/.claude/checkpoints`)
2. Install monitoring scripts to `~/.claude/hooks/`
3. Configure Claude Code hooks in `~/.claude/settings.json`
4. Set up the dashboard at `~/.claude/rate-limit-dashboard.sh`
5. Create default configuration at `~/.claude/rate-limit-config.json`
6. Install required dependencies (jq)

## 📊 Usage

### Dashboard

Launch the interactive dashboard to monitor your rate limits in real-time:

```bash
~/.claude/rate-limit-dashboard.sh
```

Dashboard Controls:
- `q` - Quit
- `r` - Refresh immediately
- `c` - Create manual checkpoint
- `h` - Show help

### Manual Commands

```bash
# Create a manual checkpoint
~/.claude/hooks/auto-checkpoint.sh manual

# List available checkpoints
~/.claude/hooks/auto-checkpoint.sh list

# Recover from a checkpoint
~/.claude/hooks/auto-checkpoint.sh recover [checkpoint-name]

# Check context status
~/.claude/hooks/context-manager.sh status

# Force context optimization
~/.claude/hooks/context-manager.sh compact
```

## ⚙️ Configuration

Edit `~/.claude/rate-limit-config.json` to customize:

```json
{
  "warning_threshold": 80,        // Warn at 80% usage
  "critical_threshold": 95,       // Block at 95% usage
  "auto_compact_threshold": 75,   // Suggest compact at 75%
  "token_warning_threshold": 150000,
  "token_compact_threshold": 180000,
  "max_context_size": 200000
}
```

## 🔧 How It Works

### Automatic Monitoring

The system uses Claude Code's hook system to monitor every operation:

1. **PreToolUse**: Checks rate limits before tool execution
2. **PostToolUse**: Updates metrics after completion
3. **UserPromptSubmit**: Validates capacity before processing
4. **PreCompact**: Creates checkpoint before context compaction
5. **Stop**: Auto-checkpoint when conversation ends

### Rate Limit Thresholds

| Level | Threshold | Action |
|-------|-----------|--------|
| Normal | < 75% | Normal operation |
| Warning | 75-80% | Suggest checkpoint, monitor closely |
| Critical | 80-95% | Auto-checkpoint, strong warnings |
| Blocked | > 95% | Block operations, force wait |

### Checkpoint System

Checkpoints automatically save:
- Conversation history
- Current rate limit status
- Git status and uncommitted changes
- Working directory and session metadata
- Open files list

## 🚨 Preventing 500 Errors

The system prevents 500 errors through:

1. **Proactive Monitoring**: Checks limits before each operation
2. **Smart Checkpointing**: Saves state before risky operations
3. **Context Management**: Suggests compaction when approaching limits
4. **Automatic Blocking**: Prevents operations when limits are critical
5. **Quick Recovery**: Easy restoration from checkpoints if issues occur

## 📝 Environment Variables

Set your Anthropic API key:

```bash
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`) for persistence.

## 🛠️ Troubleshooting

### API Key Not Set
```bash
export ANTHROPIC_API_KEY="your-key-here"
```

### Dashboard Not Updating
- Check if jq is installed: `which jq`
- Verify API key is set: `echo $ANTHROPIC_API_KEY`
- Check logs: `tail -f /tmp/claude-rate-monitor.log`

### Hooks Not Triggering
- Verify settings.json: `cat ~/.claude/settings.json | jq '.hooks'`
- Check hook permissions: `ls -la ~/.claude/hooks/`
- Review Claude Code logs for hook errors

### Checkpoint Recovery Issues
- List checkpoints: `~/.claude/hooks/auto-checkpoint.sh list`
- Manual recovery: `cd ~/.claude/checkpoints/[checkpoint-name] && ./recover.sh`

## 🗑️ Uninstallation

To completely remove the rate limit manager:

```bash
./uninstall.sh
```

Or manually:
```bash
rm -rf ~/.claude/hooks/rate-limit-monitor.sh
rm -rf ~/.claude/hooks/auto-checkpoint.sh
rm -rf ~/.claude/hooks/context-manager.sh
rm -f ~/.claude/rate-limit-dashboard.sh
rm -f ~/.claude/rate-limit-config.json
# Edit ~/.claude/settings.json to remove hook configurations
```

## 📊 Metrics and Logs

- Rate limit cache: `/tmp/claude-rate-limits.json`
- Context metrics: `/tmp/claude-context-metrics.json`
- Monitor logs: `/tmp/claude-rate-monitor.log`
- Checkpoint logs: `/tmp/claude-checkpoint.log`
- Context logs: `/tmp/claude-context-manager.log`

## 🔄 Updates

To update to the latest version:

```bash
cd claude-rate-limit-manager
git pull
./install.sh --update
```

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report issues
- Suggest features
- Submit pull requests

## 📄 License

MIT License - Feel free to modify and distribute as needed.

## 🙏 Acknowledgments

Built for the Claude Code community to ensure smooth, uninterrupted AI-assisted development.

---

**Note**: Always ensure your API key is kept secure and never committed to version control.