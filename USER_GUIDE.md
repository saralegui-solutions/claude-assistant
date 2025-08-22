# Claude Assistant Suite - User Guide

## Table of Contents
- [Quick Start](#quick-start)
- [Overview](#overview)
- [Core Features](#core-features)
  - [Rate Limit Manager](#rate-limit-manager)
  - [Voice Assistant](#voice-assistant)
  - [Notifications](#notifications)
- [Command Reference](#command-reference)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

---

## Quick Start

### Essential Commands
```bash
# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:/home/ben/.claude"

# Launch dashboard
claude-assistant dashboard

# Create checkpoint
claude-assistant checkpoint

# Check context status
claude-assistant context

# Start voice input
claude-assistant voice
```

### Status Check
| Component | Location | Command |
|-----------|----------|---------|
| Dashboard | `~/.claude/rate-limit-dashboard.sh` | `claude-assistant dashboard` |
| Settings | `~/.claude/settings.json` | View/edit Claude Code settings |
| Rate Config | `~/.claude/rate-limit-config.json` | `claude-assistant config` |
| Hooks | `~/.claude/hooks/` | Auto-executed by Claude Code |

---

## Overview

The **Claude Assistant Suite** is a comprehensive toolkit that enhances Claude Code with intelligent rate limiting, voice interaction, and notification capabilities. It automatically monitors your API usage, prevents rate limit errors, and provides convenient ways to interact with Claude.

### Key Benefits
- **Prevents 500 errors** by monitoring rate limits in real-time
- **Voice control** for hands-free coding
- **Smart notifications** for important events
- **Automatic checkpointing** to preserve conversation context
- **Interactive dashboard** for monitoring usage and limits

---

## Core Features

### Rate Limit Manager

**Purpose:** Prevents API rate limit errors and manages context efficiently.

#### Dashboard Features
- **Real-time monitoring** of API usage (requests, input/output tokens)
- **Visual progress bars** showing usage percentages
- **Context metrics** tracking conversation size
- **Checkpoint management** for saving/restoring sessions
- **Auto-refresh** every second with color-coded warnings

#### Usage Monitoring
```bash
# Launch interactive dashboard
claude-assistant dashboard

# Dashboard Controls:
# q - Quit
# r - Manual refresh
# c - Create checkpoint
# h - Help
```

#### Automatic Protection
- **Pre-execution checks** before each Claude Code operation
- **Warning at 70%** usage (yellow indicators)
- **Critical at 90%** usage (red indicators)
- **Automatic pausing** when limits approached

### Voice Assistant

**Purpose:** Enables voice input and output for Claude Code interactions.

#### Setup Requirements
```bash
# Check Python dependencies
python3 -m pip list | grep -E "speech_recognition|pyttsx3|pyaudio"

# Install if missing
pip install SpeechRecognition pyttsx3 pyaudio
```

#### Voice Commands
```bash
# Direct voice to Claude
claude-assistant voice

# Voice to file (for review before sending)
~/.claude/voice_to_file.py

# Direct Python script
python3 ~/.claude/voice_claude_direct.py
```

#### Features
- Speech-to-text input capture
- Text-to-speech response reading
- Multiple language support
- Adjustable voice settings

### Notifications

**Purpose:** Alerts for important Claude Code events and milestones.

#### Notification Types
- **Rate limit warnings** (70%, 90% thresholds)
- **Checkpoint creation** confirmations
- **Error alerts** for failed operations
- **Task completion** notifications

#### Pushover Setup (Optional)
```bash
# Create config file
cat > ~/.pushover_config << EOF
APP_TOKEN=your_app_token_here
USER_KEY=your_user_key_here
EOF

# Test notification
~/.claude/hooks/test-pushover-sound.sh
```

#### Sound Notifications
- Location: `~/.claude/hooks/sounds/`
- Formats: WAV and MP3
- Custom sounds supported

---

## Command Reference

### Main Command: `claude-assistant`

| Command | Description | Example |
|---------|-------------|---------|
| `dashboard` | Launch rate limit dashboard | `claude-assistant dashboard` |
| `checkpoint` | Create/manage checkpoints | `claude-assistant checkpoint create` |
| `context` | Check context status | `claude-assistant context` |
| `limits` | Quick rate limit check | `claude-assistant limits` |
| `voice` | Start voice assistant | `claude-assistant voice` |
| `config` | Edit configuration | `claude-assistant config` |
| `help` | Show command help | `claude-assistant help` |

### Direct Script Access

| Script | Purpose | Location |
|--------|---------|----------|
| Rate Dashboard | Interactive monitoring | `~/.claude/rate-limit-dashboard.sh` |
| Rate Monitor | Hook script for checks | `~/.claude/hooks/rate-limit-monitor.sh` |
| Auto Checkpoint | Automatic saves | `~/.claude/hooks/auto-checkpoint.sh` |
| Context Manager | Context tracking | `~/.claude/hooks/context-manager.sh` |
| Notify | Send notifications | `~/.claude/hooks/notify.sh` |

---

## Configuration

### Settings Locations

| File | Purpose | Format |
|------|---------|--------|
| `~/.claude/settings.json` | Claude Code hooks & settings | JSON |
| `~/.claude/rate-limit-config.json` | Rate limit thresholds | JSON |
| `~/.pushover_config` | Pushover API credentials | Shell variables |

### Rate Limit Configuration

Edit `~/.claude/rate-limit-config.json`:
```json
{
  "thresholds": {
    "warning": 70,
    "critical": 90
  },
  "checkpoint": {
    "auto_enable": true,
    "interval_minutes": 30,
    "max_checkpoints": 10
  },
  "notifications": {
    "enable": true,
    "sound": true,
    "pushover": false
  }
}
```

### Hook Configuration

The system automatically configures Claude Code hooks in `settings.json`:
- **PreToolUse**: Rate limit checking before operations
- **PostToolUse**: Context tracking after operations
- **AutoCheckpoint**: Periodic conversation saves

---

## Troubleshooting

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Dashboard won't start | Check execute permissions: `chmod +x ~/.claude/*.sh` |
| Voice not working | Install dependencies: `pip install SpeechRecognition pyttsx3` |
| No notifications | Verify Pushover config: `cat ~/.pushover_config` |
| Hooks not triggering | Restart Claude Code after installation |
| PATH not found | Add to shell profile: `echo 'export PATH="$PATH:~/.claude"' >> ~/.bashrc` |

### Verification Commands

```bash
# Check installation
ls -la ~/.claude/

# Verify hooks in settings
grep -A 5 "hooks" ~/.claude/settings.json

# Test rate monitor
~/.claude/hooks/rate-limit-monitor.sh test

# Check Python for voice
python3 -c "import speech_recognition; print('Voice ready')"
```

### Log Locations
- Checkpoints: `~/.claude/checkpoints/`
- Conversations: `~/.claude/conversations/`
- Shell snapshots: `~/.claude/shell-snapshots/`

---

## Advanced Usage

### Checkpoint Management

```bash
# Manual checkpoint with description
claude-assistant checkpoint create "Before refactoring"

# List checkpoints
ls -la ~/.claude/checkpoints/

# Restore checkpoint (in Claude Code)
/checkpoint restore <checkpoint-name>
```

### Custom Notifications

```bash
# Send custom notification
~/.claude/hooks/notify.sh "Custom message" "info"

# With sound
~/.claude/hooks/notify.sh "Task complete!" "success" --sound
```

### Dashboard Automation

```bash
# Run dashboard in background with logging
~/.claude/rate-limit-dashboard.sh > ~/claude-monitor.log 2>&1 &

# Create monitoring alias
alias claude-monitor='watch -n 5 ~/.claude/hooks/rate-limit-monitor.sh'
```

### Voice Assistant Customization

```python
# Edit voice settings in ~/.claude/voice_claude_direct.py
# Adjust rate, volume, voice engine
```

### Integration with Other Tools

```bash
# Add to tmux status bar
set -g status-right '#(~/.claude/hooks/rate-limit-monitor.sh --short)'

# Create desktop notification
notify-send "Claude Assistant" "$( ~/.claude/hooks/context-manager.sh )"
```

---

## Best Practices

1. **Regular Checkpoints**: Create checkpoints before major changes
2. **Monitor Dashboard**: Keep dashboard open during intensive sessions
3. **Voice Commands**: Use for quick queries without typing
4. **Notification Setup**: Configure Pushover for remote alerts
5. **Context Management**: Clear context when switching projects

---

## Support & Resources

- **Issues**: Report at [GitHub Issues](https://github.com/anthropics/claude-code/issues)
- **Documentation**: Main docs in `/home/ben/saralegui-solutions-llc/claude-assistant/docs/`
- **Module READMEs**: Each module has its own README in `modules/*/README.md`

---

*Claude Assistant Suite v1.0 - Comprehensive Tools for Claude Code Enhancement*