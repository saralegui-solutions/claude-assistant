#!/bin/bash

# Package the Claude Rate Limit Manager for distribution
# Creates a self-contained archive ready for deployment

set -e

PACKAGE_NAME="claude-rate-limit-manager"
VERSION="1.0.0"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_NAME="${PACKAGE_NAME}-${VERSION}.tar.gz"

echo "Packaging Claude Rate Limit Manager v${VERSION}..."

# Create temporary packaging directory
TMP_DIR="/tmp/${PACKAGE_NAME}-${TIMESTAMP}"
mkdir -p "$TMP_DIR"

# Copy all necessary files
cp -r hooks "$TMP_DIR/"
cp README.md "$TMP_DIR/"
cp install.sh "$TMP_DIR/"
cp uninstall.sh "$TMP_DIR/"
cp rate-limit-dashboard.sh "$TMP_DIR/"
cp rate-limit-config.json "$TMP_DIR/"
cp settings-example.json "$TMP_DIR/"

# Create version file
echo "${VERSION}" > "$TMP_DIR/VERSION"

# Create quick install script
cat > "$TMP_DIR/quick-install.sh" << 'EOF'
#!/bin/bash
# Quick install script for Claude Rate Limit Manager
echo "Installing Claude Rate Limit Manager..."
chmod +x install.sh
./install.sh
EOF
chmod +x "$TMP_DIR/quick-install.sh"

# Create the archive
cd /tmp
tar czf "$ARCHIVE_NAME" "${PACKAGE_NAME}-${TIMESTAMP}"

# Move archive to original directory
mv "$ARCHIVE_NAME" ~/claude-rate-limit-manager/

# Clean up
rm -rf "$TMP_DIR"

echo "✓ Package created: ~/claude-rate-limit-manager/${ARCHIVE_NAME}"
echo "  Size: $(du -h ~/claude-rate-limit-manager/${ARCHIVE_NAME} | cut -f1)"
echo ""
echo "To install on another machine:"
echo "  1. Copy ${ARCHIVE_NAME} to the target machine"
echo "  2. Extract: tar xzf ${ARCHIVE_NAME}"
echo "  3. Install: cd ${PACKAGE_NAME}-* && ./quick-install.sh"