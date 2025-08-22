#!/bin/bash

echo "Claude Assistant Profile Setup"
echo "=============================="
echo ""
echo "This script will help you set up authentication profiles for Claude Assistant."
echo "Profiles allow you to use different API keys for different projects without conflicts."
echo ""

node configure.js

echo ""
echo "Setup complete! You can now use Claude Assistant with:"
echo "  npm start                    # Uses default or environment-specified profile"
echo "  CLAUDE_PROFILE=work npm start  # Uses specific profile"
echo ""
echo "To add more profiles later, run: npm run configure"