# Project Structure Guide

## Overview
This document defines the standardized structure for the Claude Assistant project and guidelines for adding new modules.

## Directory Structure

```
claude-assistant/
├── README.md                    # Main project documentation
├── LICENSE                      # Project license
├── LESSONS_LEARNED.md          # Development insights
├── PROJECT_STRUCTURE.md        # This file
├── DOCUMENTATION_RULES.md      # Documentation standards
│
├── install-interactive.sh       # Main interactive installer
├── install-claude.sh           # One-line installer script
├── quick-setup.sh              # Quick setup script
│
├── docs/                       # Documentation directory
│   ├── guides/                 # User-facing guides
│   │   ├── QUICK_START.md
│   │   ├── USER_GUIDE.md
│   │   └── SETUP_GUIDE.md
│   │
│   ├── modules/                # Module-specific documentation
│   │   ├── rate-limit-manager.md
│   │   ├── pdf-generator.md
│   │   ├── whisper-transcription.md
│   │   └── [module-name].md
│   │
│   └── archive/                # Historical/deprecated docs
│
├── modules/                    # All modular components
│   ├── [module-name]/         # Each module directory
│   │   ├── README.md          # Module documentation
│   │   ├── install.sh         # Module installer
│   │   ├── config.json        # Default configuration
│   │   ├── [main-script]      # Main executable
│   │   └── [support-files]    # Additional files
│   │
│   ├── rate-limit-manager/
│   ├── pdf-generator/
│   ├── voice-assistant/
│   ├── notifications/
│   └── whisper-transcription/
│
├── core/                       # Core system files
│   ├── lib/                   # Core libraries
│   ├── utils/                 # Utility functions
│   └── [core-components]
│
├── scripts/                    # Utility scripts
│   ├── setup-profile.sh
│   ├── check-updates.js
│   └── [utility-scripts]
│
├── hooks/                      # System hooks
│   └── [hook-scripts]
│
├── config/                     # Global configuration
│   └── [config-files]
│
└── tests/                     # Test suite (future)
    ├── unit/
    ├── integration/
    └── fixtures/
```

## Module Structure Template

### Required Structure for New Modules

```
modules/[module-name]/
├── README.md                   # REQUIRED: Module documentation
├── install.sh                  # REQUIRED: Installation script
├── config.json                 # REQUIRED: Default configuration
├── [module-name].py/sh         # REQUIRED: Main executable
├── requirements.txt            # OPTIONAL: Python dependencies
├── package.json                # OPTIONAL: Node dependencies
├── test/                       # OPTIONAL: Module tests
│   └── test_[module-name].py
└── assets/                     # OPTIONAL: Supporting files
    └── [images/sounds/data]
```

### Module Naming Conventions

1. **Directory Name:** `lowercase-with-hyphens`
   - Good: `voice-assistant`, `pdf-generator`
   - Bad: `VoiceAssistant`, `voice_assistant`

2. **Main Script:** Match module name
   - Python: `voice_assistant.py`
   - Bash: `voice-assistant.sh`

3. **Command Name:** `claude-[module]`
   - Example: `claude-whisper`, `claude-pdf`

## Creating a New Module

### Step 1: Create Module Directory
```bash
mkdir -p modules/my-new-module
cd modules/my-new-module
```

### Step 2: Create Required Files

#### README.md Template
```markdown
# Module Name

## Overview
Brief description of what this module does.

## Features
- Feature 1
- Feature 2

## Installation
\`\`\`bash
./modules/my-new-module/install.sh
\`\`\`

## Usage
\`\`\`bash
claude-mymodule [options]
\`\`\`

## Configuration
Location: `~/.claude/my-module/config.json`

## Dependencies
- Required dependency 1
- Optional dependency 2

## Troubleshooting
Common issues and solutions.
```

#### install.sh Template
```bash
#!/bin/bash
# Module Name Installer
# Part of Claude Assistant Suite

set -e

# Standard color definitions
source "../../scripts/colors.sh" 2>/dev/null || {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
    BOLD='\033[1m'
}

# Paths
CLAUDE_DIR="$HOME/.claude"
MODULE_DIR="$(dirname "$0")"
INSTALL_DIR="$CLAUDE_DIR/my-module"

# Standard functions
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              My Module Installation                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Installation logic here

main() {
    print_header
    # Installation steps
    echo "Installing My Module..."
}

main "$@"
```

#### config.json Template
```json
{
  "version": "1.0",
  "enabled": true,
  "settings": {
    "option1": "default_value",
    "option2": true,
    "option3": 123
  },
  "advanced": {
    "debug": false,
    "verbose": false
  }
}
```

### Step 3: Update Project Files

#### 1. Add to install-interactive.sh
```bash
# Add to module definitions
MODULES["my-module"]="My Module"
MODULE_DESC["my-module"]="Brief description"
MODULE_DEPS["my-module"]="dependencies"
MODULE_SIZE["my-module"]="~size"

# Add installation function
install_my_module() {
    local module_dir="$SCRIPT_DIR/modules/my-module"
    # Installation logic
}

# Add to switch case
case "$module" in
    # ...
    my-module)
        install_my_module
        ;;
esac
```

#### 2. Create Module Documentation
Create `docs/modules/my-module.md` with detailed documentation.

#### 3. Update Main README
Add module to the module table and features list.

## Configuration Standards

### Configuration Hierarchy
1. **Default:** `modules/[module]/config.json`
2. **User:** `~/.claude/[module]/config.json`
3. **Runtime:** Command-line arguments

### Configuration Schema
```json
{
  "version": "1.0",        // REQUIRED: Config version
  "enabled": true,         // REQUIRED: Module status
  "settings": {},          // REQUIRED: User settings
  "advanced": {},          // OPTIONAL: Advanced options
  "experimental": {}       // OPTIONAL: Experimental features
}
```

## Installation Standards

### Installer Requirements

1. **Check Existing Installation**
```bash
if [ -d "$INSTALL_DIR" ]; then
    # Handle reinstall/upgrade
fi
```

2. **Dependency Checking**
```bash
check_dependencies() {
    # Check and install deps
}
```

3. **Progress Feedback**
```bash
print_status "Installing..."
print_success "Complete"
print_error "Failed"
```

4. **Test Installation**
```bash
test_installation() {
    # Verify installation works
}
```

5. **Completion Summary**
```bash
print_completion() {
    # Show what was installed
    # Show next steps
}
```

## Command Integration

### Binary Installation
All module commands go to: `~/.claude/bin/`

### Command Naming
- Primary: `claude-[module]`
- Alias: `[short-name]` (if applicable)

### Command Template
```bash
#!/bin/bash
# Claude Module Command Wrapper

CLAUDE_HOME="$HOME/.claude"
MODULE_HOME="$CLAUDE_HOME/my-module"

# Execute module
python3 "$MODULE_HOME/my_module.py" "$@"
```

## Testing Requirements

### Module Tests
```
modules/[module]/test/
├── test_installation.sh    # Installation test
├── test_functionality.py   # Functional tests
└── test_integration.sh     # Integration test
```

### Test Execution
```bash
# Run module tests
./modules/[module]/test/test_installation.sh

# Run all tests
./run_tests.sh --module [module]
```

## Documentation Requirements

### Module README Must Include:
1. **Overview** - What it does
2. **Features** - Key capabilities  
3. **Installation** - How to install
4. **Usage** - Common commands
5. **Configuration** - Settings explanation
6. **Dependencies** - Required software
7. **Troubleshooting** - Common issues
8. **API/Integration** - For developers

### Documentation Locations
- Module README: `modules/[module]/README.md`
- User Guide: `docs/modules/[module].md`
- Quick Reference: In main README.md

## Version Management

### Version Format
`MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes
- MINOR: New features
- PATCH: Bug fixes

### Version Locations
1. Module config.json: `"version": "1.0.0"`
2. Install script: `MODULE_VERSION="1.0.0"`
3. README.md: `Version: 1.0.0`

## Best Practices

### Do's
✅ Keep modules independent
✅ Include comprehensive error handling
✅ Provide multiple installation methods
✅ Document all configuration options
✅ Test on multiple platforms
✅ Include uninstall instructions
✅ Use consistent styling
✅ Provide examples

### Don'ts
❌ Don't assume dependencies exist
❌ Don't modify system files without permission
❌ Don't hardcode paths
❌ Don't ignore error cases
❌ Don't skip documentation
❌ Don't break existing modules
❌ Don't use unclear naming
❌ Don't forget cleanup on failure

## Module Categories

### Current Categories
1. **Monitoring** - Rate limiting, tracking
2. **Productivity** - PDF, documentation
3. **Input/Output** - Voice, transcription
4. **Notifications** - Alerts, messaging
5. **Utilities** - Helper tools

### Adding New Categories
1. Create category documentation
2. Update installer categories
3. Group related modules

## Maintenance

### Regular Tasks
- Update dependencies
- Test compatibility
- Update documentation
- Review user feedback
- Security updates

### Deprecation Process
1. Mark as deprecated in README
2. Add warning to installer
3. Provide migration path
4. Remove after 2 versions

## Contributing

### Submission Checklist
- [ ] Module follows structure template
- [ ] All required files present
- [ ] Installation tested on Linux/macOS
- [ ] Documentation complete
- [ ] No hardcoded paths
- [ ] Error handling implemented
- [ ] Integration with main installer
- [ ] Version information included

---

*This structure ensures consistency, maintainability, and ease of use across all Claude Assistant modules.*