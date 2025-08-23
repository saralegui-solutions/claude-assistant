# Documentation Rules and Auto-Update Guidelines

## Overview
This document defines rules and procedures for maintaining documentation, especially regarding automatic updates when modules are added or changed.

## Documentation Hierarchy

### Level 1: Project Documentation
- **README.md** - Main entry point
- **QUICK_START.md** - Getting started
- **LICENSE** - Legal information

### Level 2: Meta Documentation  
- **LESSONS_LEARNED.md** - Development insights
- **PROJECT_STRUCTURE.md** - Structure guide
- **DOCUMENTATION_RULES.md** - This file

### Level 3: User Guides
- **docs/guides/*** - User-facing guides
- **docs/modules/*** - Module documentation

### Level 4: Module Documentation
- **modules/*/README.md** - Module-specific docs

## Auto-Update Rules

### When Adding a New Module

#### 1. README.md Updates

**Module Table Addition:**
```markdown
| Module | Description | Size | Dependencies |
|--------|-------------|------|--------------|
| **New Module** | Brief description | ~size | deps |
```

**Features Section:**
```markdown
### 📦 New Module Name
Brief description of capabilities:
- Feature 1
- Feature 2
- Feature 3
```

**Quick Commands:**
```markdown
### Essential Commands
\`\`\`bash
new-cmd         # New module command
\`\`\`
```

#### 2. Install Script Updates

**install-interactive.sh:**
```bash
# Add to module definitions
MODULES["new-module"]="New Module Name"
MODULE_DESC["new-module"]="Description"
MODULE_DEPS["new-module"]="dependencies"
MODULE_SIZE["new-module"]="~size"

# Add installation function
install_new_module() {
    # Installation logic
}
```

#### 3. Documentation Creation

**Required Files:**
1. `modules/new-module/README.md` - Module documentation
2. `docs/modules/new-module.md` - Detailed user guide

### Automatic README Generation

#### Script Template: update-readme.sh
```bash
#!/bin/bash
# Auto-update README with module information

# Scan modules directory
MODULES=$(ls -d modules/*/ | xargs -n1 basename)

# Generate module table
generate_module_table() {
    echo "| Module | Description | Size | Dependencies |"
    echo "|--------|-------------|------|--------------|"
    
    for module in $MODULES; do
        # Extract from module's config.json
        desc=$(jq -r '.description' modules/$module/config.json)
        size=$(du -sh modules/$module | cut -f1)
        deps=$(jq -r '.dependencies | join(", ")' modules/$module/config.json)
        
        echo "| **$module** | $desc | $size | $deps |"
    done
}

# Update README
update_readme() {
    # Backup current README
    cp README.md README.md.bak
    
    # Generate new sections
    module_table=$(generate_module_table)
    
    # Update README sections
    # ... (sed commands to update sections)
}
```

## Documentation Standards

### 1. README.md Standards

#### Structure
```markdown
# Project Name

> One-line description

## ⚡ Quick Install
Installation command

## 🎯 What It Does
Brief overview

## 📦 Modular Architecture
Module table

## 🚀 Quick Start
Essential commands

## 📁 Project Structure
Directory tree

## 🔧 Installation Options
Detailed options

## 📊 Module Details
Per-module features

## 🛠️ Requirements
System requirements

## 📚 Documentation
Links to guides

## 🆘 Troubleshooting
Common issues

## 🤝 Contributing
Contribution guide

## 📄 License
License info
```

#### Update Frequency
- On module addition/removal
- On major feature changes
- On installation process changes

### 2. Module Documentation Standards

#### Required Sections
1. **Overview** - What it does
2. **Features** - Capabilities list
3. **Installation** - How to install
4. **Usage** - Command examples
5. **Configuration** - Settings
6. **Dependencies** - Requirements
7. **Troubleshooting** - Issues/solutions
8. **API Reference** - For developers

#### Template: modules/*/README.md
```markdown
# Module Name

## Overview
Brief description

## Features
- ✨ Feature 1
- 🚀 Feature 2
- 💡 Feature 3

## Installation

### Via Interactive Installer
\`\`\`bash
./install-interactive.sh
# Select: [N] Module Name
\`\`\`

### Manual Installation
\`\`\`bash
./modules/module-name/install.sh
\`\`\`

## Usage

### Basic Commands
\`\`\`bash
claude-module [options]
\`\`\`

### Examples
\`\`\`bash
# Example 1
claude-module input.file

# Example 2
claude-module --option value
\`\`\`

## Configuration

### File Location
\`~/.claude/module/config.json\`

### Options
\`\`\`json
{
  "setting": "value"
}
\`\`\`

## Dependencies
- Dependency 1
- Dependency 2

## Troubleshooting

### Issue 1
Solution 1

### Issue 2
Solution 2

## Version
Current: 1.0
```

## Versioning Documentation

### Version Change Documentation

#### Major Version (X.0.0)
- Full documentation review
- Migration guide required
- Changelog with breaking changes
- Update all examples

#### Minor Version (x.Y.0)
- Feature documentation
- New examples
- Update command reference
- Compatibility notes

#### Patch Version (x.y.Z)
- Bug fix notes
- Updated troubleshooting
- No structural changes

### CHANGELOG.md Format
```markdown
# Changelog

## [2.0.0] - 2024-12-22
### Breaking Changes
- Change description

### Added
- New feature

### Fixed
- Bug fix

### Removed
- Deprecated feature
```

## Quick Reference Updates

### One-Line Install Update
When installation changes:
```markdown
## ⚡ Quick Install
\`\`\`bash
# Updated command
curl -sSL https://...new-url... | bash
\`\`\`
```

### Command Alias Updates
When adding new aliases:
```markdown
### Essential Commands
\`\`\`bash
cl              # Interactive launcher
new-alias       # New functionality
\`\`\`
```

## Documentation Automation

### Pre-Commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check if modules changed
if git diff --cached --name-only | grep -q "^modules/"; then
    echo "Updating documentation..."
    ./scripts/update-docs.sh
    git add README.md docs/
fi
```

### CI/CD Documentation
```yaml
# .github/workflows/docs.yml
name: Update Documentation

on:
  push:
    paths:
      - 'modules/**'
      - 'install-interactive.sh'

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Update README
        run: ./scripts/update-readme.sh
      - name: Commit changes
        run: |
          git config user.name "Doc Bot"
          git config user.email "bot@example.com"
          git add .
          git commit -m "Auto-update documentation"
          git push
```

## Documentation Testing

### Link Checking
```bash
#!/bin/bash
# Check all markdown links

find . -name "*.md" -exec markdown-link-check {} \;
```

### Structure Validation
```bash
#!/bin/bash
# Validate documentation structure

check_module_docs() {
    for module in modules/*/; do
        module_name=$(basename "$module")
        
        # Check required files
        [ -f "$module/README.md" ] || echo "Missing: $module/README.md"
        [ -f "docs/modules/$module_name.md" ] || echo "Missing: docs/modules/$module_name.md"
    done
}
```

## Style Guide

### Formatting Rules

#### Headers
- Use ATX-style headers (#)
- Leave blank line before/after

#### Code Blocks
- Use triple backticks
- Specify language
- Include comments

#### Lists
- Use - for unordered
- Use 1. for ordered
- Indent with 2 spaces

#### Tables
- Use pipes |
- Align with spaces
- Include header separator

### Writing Style

#### Tone
- Professional but friendly
- Direct and concise
- Action-oriented

#### Voice
- Active voice preferred
- Second person for instructions
- Present tense for descriptions

### Emoji Usage

#### Standard Emojis
- ⚡ Quick/Fast
- 🚀 Launch/Start
- 📦 Package/Module
- 🎯 Target/Goal
- 🔧 Configuration
- 📚 Documentation
- 🆘 Help/Support
- ✅ Success/Complete
- ❌ Error/Failed
- ⚠️ Warning

## Review Process

### Documentation Review Checklist

#### Before Commit
- [ ] Spell check passed
- [ ] Links verified
- [ ] Code examples tested
- [ ] Formatting consistent
- [ ] Version updated

#### Before Release
- [ ] All modules documented
- [ ] Installation guide current
- [ ] Troubleshooting updated
- [ ] Examples working
- [ ] Cross-references valid

## Common Documentation Tasks

### Adding a Module
1. Create module README
2. Create user guide
3. Update main README
4. Update installer
5. Add to module table
6. Add to features list
7. Add commands
8. Test all examples

### Removing a Module
1. Archive documentation
2. Update main README
3. Update installer
4. Remove from tables
5. Add deprecation notice
6. Provide migration path

### Updating Commands
1. Update command in code
2. Update README examples
3. Update module docs
4. Update quick start
5. Update aliases
6. Test all examples

## Documentation Maintenance

### Weekly Tasks
- Check for broken links
- Review recent changes
- Update examples
- Fix reported issues

### Monthly Tasks
- Full documentation review
- Update troubleshooting
- Review user feedback
- Update best practices

### Per Release
- Version all documents
- Generate changelog
- Update installation guide
- Test all procedures

## Tools and Scripts

### Documentation Generator
```bash
#!/bin/bash
# generate-docs.sh

# Generate module documentation
for module in modules/*/; do
    ./scripts/generate-module-doc.sh "$module"
done

# Update main README
./scripts/update-readme.sh

# Generate API docs
./scripts/generate-api-docs.sh
```

### Documentation Validator
```bash
#!/bin/bash
# validate-docs.sh

# Check structure
./scripts/check-structure.sh

# Validate links
./scripts/check-links.sh

# Test examples
./scripts/test-examples.sh
```

## Best Practices

### Do's
✅ Keep documentation next to code
✅ Update docs with code changes
✅ Include examples for everything
✅ Test all commands shown
✅ Version documentation
✅ Automate where possible
✅ Review regularly

### Don'ts
❌ Don't document future features
❌ Don't leave TODOs in docs
❌ Don't use absolute paths
❌ Don't assume knowledge
❌ Don't skip error cases
❌ Don't use outdated examples
❌ Don't forget maintenance

---

*These rules ensure documentation remains accurate, helpful, and automatically updated with project changes.*