# Claude API Orchestrator Module

## Overview

The Claude API Orchestrator is a revolutionary module that creates a seamless workflow between Claude's API (for planning and verification) and Claude Code (for execution). This creates a fully automated, hands-free development experience where complex projects can be completed with minimal user intervention.

## Architecture

```
Voice/Text Input → Claude API (Planning) → Claude Code (Execution) → Claude API (Verification) → Loop/Complete
```

### Key Components

1. **Claude API Brain**: Handles high-level planning, task breakdown, and verification
2. **Claude Code Executor**: Performs actual file operations, coding, and system commands
3. **Orchestrator**: Coordinates between the two, managing state and flow control
4. **Session Management**: Tracks all operations for review and debugging

## Installation

### Quick Install
```bash
# From the claude-assistant directory
./install.sh --module api-orchestrator

# Or install all modules including orchestrator
./install.sh --all
```

### Manual Install
```bash
cd modules/api-orchestrator
./install.sh
```

### Voice Input Setup (Optional)

To enable voice input functionality:

#### Automatic Installation
```bash
# Run the voice dependencies installer
modules/api-orchestrator/install-voice-deps.sh
```

#### Manual Installation

**Ubuntu/Debian/WSL:**
```bash
# Install system packages
sudo apt-get update
sudo apt-get install -y python3-pyaudio portaudio19-dev python3-dev

# Install Python packages
pip3 install SpeechRecognition pyaudio --user --break-system-packages
```

**macOS:**
```bash
# Install PortAudio
brew install portaudio

# Install Python packages
pip3 install SpeechRecognition pyaudio --user
```

### WSL Real Voice Input Setup

The orchestrator now supports **real voice input in WSL** using PulseAudio!

#### Automatic Setup
```bash
# Run when you first use claude-assistant
# It will auto-initialize if not set up
claude-assistant orch-voice
```

#### Manual Setup

**Step 1: Install PulseAudio in WSL**
```bash
# Run the setup script
modules/api-orchestrator/setup-wsl-audio.sh
```

**Step 2: Install PulseAudio on Windows**

Option A: Using Chocolatey (Recommended)
```powershell
# In Windows PowerShell as Administrator
choco install pulseaudio

# Configure it (add to C:\ProgramData\chocolatey\lib\pulseaudio\tools\etc\pulse\default.pa):
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;172.16.0.0/12

# Run PulseAudio
C:\ProgramData\chocolatey\lib\pulseaudio\tools\pulseaudio.exe
```

Option B: Manual Installation
1. Download from: https://www.freedesktop.org/wiki/Software/PulseAudio/Ports/Windows/
2. Extract and configure as above
3. Run pulseaudio.exe

**Step 3: Test Connection**
```bash
# In WSL
pactl info  # Should show server info

# Test voice
claude-assistant orch-voice  # Will use real microphone!
```

#### How It Works

1. **Auto-Detection**: Orchestrator detects WSL environment
2. **PulseAudio Check**: Tests if Windows PulseAudio is running
3. **Smart Fallback**: 
   - If PulseAudio connected → Real voice input
   - If not connected → Text-based voice interface
   - If no audio libs → Pure text input

#### Troubleshooting

- **No audio devices**: Make sure PulseAudio is running on Windows
- **Connection refused**: Check Windows firewall settings
- **Can't find microphone**: Allow microphone access in Windows settings
- **Setup instructions**: See `~/pulseaudio-windows-setup.txt` after running setup

### Requirements

#### Core Requirements
- Python 3.6+
- `anthropic` Python package
- Claude Code installed and configured
- Anthropic API key

#### Voice Input Requirements (Optional)
- `SpeechRecognition` Python package
- `PyAudio` Python package
- PortAudio system libraries

Voice input is optional - the orchestrator works perfectly with text input if voice dependencies are not installed.

## Configuration

### API Key Setup

The orchestrator needs your Anthropic API key. Set it using one of these methods:

1. **Environment Variable** (Recommended):
```bash
export ANTHROPIC_API_KEY='sk-ant-api03-...'
```

2. **Config File**:
The orchestrator will prompt for your key on first run and save it to:
```
~/.claude/config/api_key.json
```

3. **Per-Session**:
You'll be prompted if no key is found.

## Usage

### Command Line Interface

#### Start with Voice Input
```bash
claude-orchestrate
# or
claude-assistant orch-voice
```

#### Start with Text Input
```bash
claude-orchestrate "Create a Python web scraper for product prices"
# or
claude-assistant orch "Build a REST API with FastAPI"
```

#### Using Aliases
```bash
# Source the aliases file
source ~/.claude/modules/api-orchestrator/aliases.sh

# Then use shortcuts
orch                    # Start with voice
orch-text "request"     # Start with text
orch-review            # Review sessions
orch-log               # View latest log
orch-clean             # Clean old sessions
```

### Interactive Workflow

1. **Initial Request**: Provide your requirements via voice or text
2. **Planning Phase**: Claude API creates a structured plan
3. **Execution Phase**: Claude Code implements the plan
4. **Verification Phase**: Claude API verifies results
5. **Iteration**: System automatically iterates until complete

### Checkpoint System

At major milestones, the orchestrator pauses for review:

- **[c]ontinue**: Proceed with execution
- **[r]eview**: Show detailed results
- **[m]odify**: Provide new instructions
- **[v]oice**: Add voice instructions
- **[s]top**: End session

## Examples

### Example 1: Web Scraper
```bash
$ claude-orchestrate "Create a web scraper that monitors Amazon prices and sends alerts"

🚀 Claude Orchestrated Session
🧠 Planning with Claude API...
📍 Iteration 1 - Phase: PLANNING
📋 Creating price monitoring system with notifications

📝 Executing 3 tasks:
  [1/3] Creating project structure
  ✓ Task completed: Creating project structure
  [2/3] Implementing scraper module
  ✓ Task completed: Implementing scraper module
  [3/3] Setting up notification system
  ✓ Task completed: Setting up notification system

🛑 CHECKPOINT - Review and decide next action
👉 Your choice [c/r/m/v/s]: c

🔄 Getting next steps from Claude API...
📍 Iteration 2 - Phase: VERIFICATION
✅ All tests passing
🎉 Project completed successfully!
```

### Example 2: Bug Fix
```bash
$ claude-orchestrate "My pytest tests are failing with import errors"

🚀 Claude Orchestrated Session
🧠 Planning with Claude API...
📍 Iteration 1 - Phase: PLANNING
📋 Analyzing test failures and import structure

📝 Executing 2 tasks:
  [1/2] Analyzing current project structure
  [2/2] Identifying import issues

📍 Iteration 2 - Phase: EXECUTION
📋 Fixing import paths and dependencies
...
```

### Example 3: Full Stack Application
```bash
$ claude-orchestrate
🎤 Speak your requirements...
"Build a todo app with React frontend and FastAPI backend with SQLite"

🧠 Planning with Claude API...
📍 Iteration 1 - Phase: PLANNING
📋 Creating full-stack todo application
...
```

## Session Management

### Session Files

All sessions are saved in `~/.claude/orchestrated-sessions/`:

- `session_YYYYMMDD_HHMMSS.log` - Detailed execution log
- `session_YYYYMMDD_HHMMSS_summary.json` - Structured session data
- `prompt_*.txt` - Individual prompts sent to Claude Code

### Reviewing Sessions

```bash
# List recent sessions
claude-assistant orch-review

# View specific session
cat ~/.claude/orchestrated-sessions/session_20240124_143022_summary.json

# View session log
less ~/.claude/orchestrated-sessions/session_20240124_143022.log
```

### Cleaning Up

```bash
# Remove old sessions (keeps last 20 files)
source ~/.claude/modules/api-orchestrator/aliases.sh
orch-clean
```

## Advanced Features

### Custom System Prompts

Modify the orchestrator.py to customize Claude API's behavior:

```python
system="""You are helping orchestrate a Claude Code session.
Add your custom instructions here..."""
```

### Task Types

The orchestrator supports three task types:

1. **claude_code_prompt**: Sends prompts to Claude Code
2. **file_creation**: Creates files directly
3. **command**: Executes shell commands

### Rate Limiting

Built-in rate limiting prevents API throttling:
- 1-second delay between API calls
- 2-minute timeout for Claude Code operations
- 1-minute timeout for shell commands

## Troubleshooting

### Common Issues

1. **"No API key found"**
   - Set `ANTHROPIC_API_KEY` environment variable
   - Or run orchestrator once to enter key

2. **"Python 3 is required"**
   - Install Python 3.6 or higher
   - Ensure `python3` is in PATH

3. **"anthropic package not found"**
   ```bash
   pip3 install anthropic
   ```

4. **"claude-code: command not found"**
   - Ensure Claude Code is installed
   - Check alias: `alias claude-code='claude --dangerously-skip-permissions'`

5. **Session hangs**
   - Press Ctrl+C to interrupt
   - Sessions have a 15-iteration safety limit

### Debug Mode

View detailed logs:
```bash
tail -f ~/.claude/orchestrated-sessions/session_*.log
```

## Integration with Other Modules

### Voice Assistant
The orchestrator automatically uses the voice assistant module if installed for voice input.

### Rate Limit Manager
Works alongside the rate limit manager to prevent API throttling.

### Notifications
Can be extended to send notifications at checkpoints or completion.

## Best Practices

1. **Clear Requirements**: Be specific in your initial request
2. **Use Checkpoints**: Review at checkpoints for complex projects
3. **Iterative Refinement**: Use modify option to adjust course
4. **Session Review**: Check logs for debugging
5. **Clean Regularly**: Run `orch-clean` periodically

## Security

- API keys are stored locally in `~/.claude/config/`
- Never commit API keys to version control
- Sessions may contain sensitive data - review before sharing

## Future Enhancements

Planned features:
- Parallel task execution
- Web UI for session monitoring
- Integration with CI/CD pipelines
- Custom task type plugins
- Session replay functionality
- Multi-model support (GPT-4, etc.)

## Support

For issues or questions:
1. Check session logs for detailed error messages
2. Review this documentation
3. Open an issue on the GitHub repository

## License

Part of the Claude Assistant Suite
MIT License - See main project LICENSE file