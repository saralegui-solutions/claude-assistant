#!/bin/bash

# Claude Assistant - Project Reorganization Script
# This script reorganizes the project structure for better modularity

set -e

echo "Reorganizing Claude Assistant project structure..."

# Create new directory structure
mkdir -p docs/guides
mkdir -p docs/archive
mkdir -p core
mkdir -p scripts
mkdir -p config

# Move documentation to organized locations
echo "Organizing documentation..."

# Move main docs to docs/guides
mv -f USER_GUIDE.md docs/guides/USER_GUIDE.md 2>/dev/null || true
mv -f COMPLETE_SETUP_GUIDE.md docs/guides/COMPLETE_SETUP_GUIDE.md 2>/dev/null || true
mv -f QUICK_START.md docs/guides/QUICK_START.md 2>/dev/null || true
mv -f README_SETUP.md docs/guides/SETUP_INSTRUCTIONS.md 2>/dev/null || true

# Keep main README at root
# README.md stays at root

# Move scripts to scripts directory
echo "Organizing scripts..."
mv -f check-updates.js scripts/ 2>/dev/null || true
mv -f configure.js scripts/ 2>/dev/null || true
mv -f setup.js scripts/ 2>/dev/null || true
mv -f setup-profile.sh scripts/ 2>/dev/null || true
mv -f install_tailscale.sh scripts/ 2>/dev/null || true

# Move core files
echo "Organizing core files..."
mv -f index.js core/ 2>/dev/null || true
mv -f lib core/ 2>/dev/null || true
mv -f utils core/ 2>/dev/null || true

# Keep package files at root
# package.json, package-lock.json stay at root

# Keep installer scripts at root for easy access
# install.sh, quick-setup.sh, install-claude.sh stay at root

echo "Reorganization complete!"
echo ""
echo "New structure:"
echo "├── README.md                 # Main documentation"
echo "├── install.sh                # Main installer"
echo "├── docs/"
echo "│   ├── guides/              # User guides"
echo "│   └── archive/             # Archived docs"
echo "├── modules/                 # All modules"
echo "│   ├── rate-limit-manager/"
echo "│   ├── notifications/"
echo "│   ├── voice-assistant/"
echo "│   └── pdf-generator/"
echo "├── core/                    # Core application files"
echo "├── scripts/                 # Utility scripts"
echo "├── config/                  # Configuration files"
echo "└── hooks/                   # Hook scripts"