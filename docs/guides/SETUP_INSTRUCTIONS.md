# Claude Assistant - Quick Setup Guide

## One-Command Setup

Run the complete setup wizard with a single command:

```bash
npm run setup
```

This interactive wizard will:
1. ✅ Configure API key profiles (supports multiple keys/projects)
2. ✅ Set up optional Pushover notifications
3. ✅ Enable automatic model version updates
4. ✅ Install shell startup hooks
5. ✅ Check and update any deprecated models

## Features

### 🔑 Profile-Based Authentication
- **No API key conflicts** between projects
- Store multiple API keys securely in `~/.claude-assistant/config.json`
- Switch profiles easily: `CLAUDE_PROFILE=work npm start`

### 🔄 Automatic Model Updates
- Detects deprecated Claude models automatically
- Updates models in all configuration files
- Optional auto-commit and push to git
- Runs on:
  - Terminal startup
  - Claude Code startup
  - Manual check: `npm run check-updates`

### 📱 Optional Notifications
- Pushover integration for mobile alerts
- Notifications for long-running tasks
- Rate limit warnings

## Usage After Setup

```bash
# Start with default profile
npm start

# Use specific profile
CLAUDE_PROFILE=personal npm start

# Check for model updates manually
npm run check-updates

# Add new profiles
npm run configure

# Force update check
node check-updates.js --force
```

## Configuration Locations

- **API Keys**: `~/.claude-assistant/config.json` (secure, user-specific)
- **Update Settings**: `~/.claude-assistant/updater.json`
- **Project Config**: `./config/claude-assistant.config.json`
- **Pushover**: `~/.pushover_config`

## Model Update Behavior

The updater will:
1. Check for deprecated models every 24 hours
2. Notify you of available updates
3. Apply updates with your confirmation
4. Optionally commit and push changes to git

### Supported Model Migrations
- `claude-2.*` → `claude-3-5-sonnet-20241022`
- `claude-instant-1.*` → `claude-3-5-haiku-20241022`
- `claude-3-opus-20240229` → Latest Opus version
- `claude-3-sonnet-20240229` → `claude-3-5-sonnet-20241022`
- `claude-3-haiku-20240307` → `claude-3-5-haiku-20241022`

## Troubleshooting

### API Key Issues
```bash
# List all profiles
npm run configure
# Choose option 2

# Set different default profile
npm run configure
# Choose option 3
```

### Model Update Issues
```bash
# Force immediate check
node check-updates.js --force

# Check without applying
node check-updates.js

# Disable auto-updates
# Edit ~/.claude-assistant/updater.json
# Set "enabled": false
```

### Remove Startup Hooks
Remove these lines from `~/.bashrc` or `~/.zshrc`:
```bash
# Claude Assistant Auto-Update Check
```

## Security Notes

- API keys are stored with 600 permissions (user-only read/write)
- Never commit `.env` files with API keys
- Use profiles instead of project-specific keys
- Keys are encrypted at rest in `~/.claude-assistant/`

## Support

For issues or questions:
- Check existing configurations: `npm run configure`
- View update logs: `cat ~/.claude-assistant/.last-update-check`
- Manual update check: `npm run check-updates`