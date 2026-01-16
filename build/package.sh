#!/bin/bash

#
# package.sh - Build macOS .pkg installer for Touch ID for Sudo
# Creates a professional .pkg installer for distribution
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Touch ID for Sudo - macOS Package Creator (.pkg)             ║"
echo "║  Creates a professional installer for easy distribution       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
WORK_DIR="/tmp/touchid-build-$$"
VERSION="1.0.0"
PKG_NAME="TouchID-for-Sudo-$VERSION"
PKG_FILE="$PROJECT_DIR/$PKG_NAME.pkg"

# Cleanup function
cleanup() {
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup EXIT

log_info "Creating macOS installer package..."
log_info "Project directory: $PROJECT_DIR"
log_info "Version: $VERSION"
echo ""

# Step 1: Check prerequisites
log_info "Step 1: Checking prerequisites..."

if ! command -v clang &> /dev/null; then
    log_error "Xcode Command Line Tools not found"
    echo "Install with: xcode-select --install"
    exit 1
fi

if ! command -v pkgbuild &> /dev/null; then
    log_error "pkgbuild not found (requires Xcode)"
    exit 1
fi

log_success "Prerequisites verified"
echo ""

# Step 2: Build PAM module using Make
log_info "Step 2: Building Touch ID PAM module..."

if [ ! -f "$PROJECT_DIR/src/pam_touchid.m" ]; then
    log_error "Source file not found: $PROJECT_DIR/src/pam_touchid.m"
    exit 1
fi

cd "$PROJECT_DIR"

# Build using makefile
if ! make clean build 2>&1 > /dev/null; then
    log_error "Failed to build PAM module"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/build/pam_touchid.so" ]; then
    log_error "PAM module not created"
    exit 1
fi

log_success "PAM module compiled: $PROJECT_DIR/build/pam_touchid.so"
echo ""

# Step 3: Create package structure
log_info "Step 3: Creating package structure..."

mkdir -p "$WORK_DIR/payload/usr/local/lib/pam"
mkdir -p "$WORK_DIR/payload/usr/local/bin"
mkdir -p "$WORK_DIR/scripts"

log_success "Package directories created"
echo ""

# Step 4: Copy PAM module
log_info "Step 4: Copying PAM module..."
cp "$PROJECT_DIR/build/pam_touchid.so" "$WORK_DIR/payload/usr/local/lib/pam/pam_touchid.so"
chmod 755 "$WORK_DIR/payload/usr/local/lib/pam/pam_touchid.so"
log_success "PAM module installed"
echo ""

# Step 5: Create helper scripts
log_info "Step 5: Creating helper scripts..."

cat > "$WORK_DIR/scripts/preinstall" << 'PREINSTALL'
#!/bin/bash
echo "Validating installation environment..."
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Must run as root"
    exit 1
fi
exit 0
PREINSTALL

cat > "$WORK_DIR/scripts/postinstall" << 'POSTINSTALL'
#!/bin/bash

# Enable logging to system log
exec 1> >(logger -s -t "touchid-postinstall")
exec 2>&1

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Touch ID for Sudo - Configuration in Progress               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Configuration paths
PAM_MODULE="/usr/local/lib/pam/pam_touchid.so"
SUDO_PAM="/etc/pam.d/sudo"
BACKUP_PAM="/etc/pam.d/sudo.backup.touchid"

echo "DEBUG: Postinstall script executing as UID $(id -u)"
echo "DEBUG: PAM_MODULE=$PAM_MODULE"
echo "DEBUG: SUDO_PAM=$SUDO_PAM"

# Verify PAM module exists
if [ ! -f "$PAM_MODULE" ]; then
    echo "✗ Error: PAM module not found at $PAM_MODULE"
    echo "Installation may have failed"
    exit 1
fi

echo "✓ PAM module verified"

# Backup original sudo PAM config if not already backed up
if [ ! -f "$BACKUP_PAM" ]; then
    cp "$SUDO_PAM" "$BACKUP_PAM"
    echo "✓ Backed up original sudo configuration"
fi

# Configure sudo to use Touch ID
# Modern macOS uses /etc/pam.d/sudo_local for local customizations
SUDO_LOCAL="/etc/pam.d/sudo_local"
SUDO_LOCAL_BACKUP="/etc/pam.d/sudo_local.backup.touchid"

if [ ! -f "$SUDO_LOCAL" ]; then
    echo "✓ Creating sudo_local for Touch ID configuration"
    
    # Create sudo_local with Touch ID configuration
    cat > "$SUDO_LOCAL" << 'SUDO_LOCAL_CONTENT'
# sudo_local: local sudo PAM configuration
# Added for Touch ID support - customize this file

auth       sufficient     /usr/local/lib/pam/pam_touchid.so
SUDO_LOCAL_CONTENT
    
    chmod 644 "$SUDO_LOCAL"
    echo "DEBUG: Created $SUDO_LOCAL with Touch ID configuration"
else
    # sudo_local exists - check if already configured
    if ! grep -q "pam_touchid.so" "$SUDO_LOCAL"; then
        # Backup existing sudo_local
        cp "$SUDO_LOCAL" "$SUDO_LOCAL_BACKUP"
        
        # Add Touch ID to the top of sudo_local
        {
            echo "# Added by Touch ID for Sudo installation"
            echo "auth       sufficient     /usr/local/lib/pam/pam_touchid.so"
            cat "$SUDO_LOCAL"
        } > "$SUDO_LOCAL.tmp"
        
        mv "$SUDO_LOCAL.tmp" "$SUDO_LOCAL"
        echo "DEBUG: Updated existing $SUDO_LOCAL with Touch ID configuration"
    else
        echo "ℹ Touch ID already configured in $SUDO_LOCAL"
        echo "DEBUG: Touch ID already in sudo_local"
    fi
fi

# Verify configuration was applied
if grep -q "pam_touchid.so" "$SUDO_LOCAL" 2>/dev/null; then
    echo "✓ Touch ID configuration verified"
    echo "DEBUG: ✓ pam_touchid.so confirmed in $SUDO_LOCAL"
else
    echo "✗ Warning: Configuration verification failed"
    echo "DEBUG: ✗ pam_touchid.so NOT found after configuration!"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Installation & Configuration Complete! ✓                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "You can now use Touch ID with sudo:"
echo "  sudo whoami"
echo ""
echo "Useful commands:"
echo "  touchid-status     - Check installation status"
echo "  sudo touchid-configure - Re-configure if needed"
echo "  sudo touchid-uninstall - Remove Touch ID from sudo"
echo ""
exit 0
POSTINSTALL

chmod +x "$WORK_DIR/scripts/preinstall" "$WORK_DIR/scripts/postinstall"
log_success "Helper scripts created"
echo ""

# Step 6: Create helper commands
log_info "Step 6: Installing helper commands..."

cat > "$WORK_DIR/payload/usr/local/bin/touchid-configure" << 'EOF'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Error: Run with sudo"
    echo "Usage: sudo touchid-configure"
    exit 1
fi

PAM_MODULE="/usr/local/lib/pam/pam_touchid.so"
SUDO_PAM="/etc/pam.d/sudo"
BACKUP="/etc/pam.d/sudo.backup.touchid"

if [ ! -f "$BACKUP" ]; then
    cp "$SUDO_PAM" "$BACKUP"
    echo "✓ Backup created"
fi

if ! grep -q "pam_touchid.so" "$SUDO_PAM"; then
    # Modern macOS: use sudo_local for local customizations
    SUDO_LOCAL="/etc/pam.d/sudo_local"
    
    if [ ! -f "$SUDO_LOCAL" ]; then
        # Create new sudo_local
        echo "auth       sufficient     $PAM_MODULE" > "$SUDO_LOCAL"
        chmod 644 "$SUDO_LOCAL"
    else
        # Add to existing sudo_local (at the top)
        cp "$SUDO_LOCAL" "$SUDO_LOCAL.bak"
        {
            echo "auth       sufficient     $PAM_MODULE"
            cat "$SUDO_LOCAL.bak"
        } > "$SUDO_LOCAL"
    fi
    
    echo "✓ Configured for Touch ID"
fi
echo "Test with: sudo whoami"
EOF

cat > "$WORK_DIR/payload/usr/local/bin/touchid-status" << 'EOF'
#!/bin/bash
echo "Touch ID for Sudo - Status"
echo "=========================="
PAM_MODULE="/usr/local/lib/pam/pam_touchid.so"
if [ -f "$PAM_MODULE" ]; then
    echo "✓ PAM module installed"
else
    echo "✗ PAM module NOT found"
fi

if grep -q "pam_touchid.so" "/etc/pam.d/sudo_local" 2>/dev/null; then
    echo "✓ Sudo configured for Touch ID"
else
    echo "ℹ Not yet configured - run: sudo touchid-configure"
fi
EOF

cat > "$WORK_DIR/payload/usr/local/bin/touchid-uninstall" << 'EOF'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Error: Run with sudo"
    exit 1
fi

# Remove Touch ID from sudo_local
SUDO_LOCAL="/etc/pam.d/sudo_local"
SUDO_LOCAL_BACKUP="/etc/pam.d/sudo_local.backup.touchid"

if [ -f "$SUDO_LOCAL" ]; then
    # Backup current state
    cp "$SUDO_LOCAL" "$SUDO_LOCAL_BACKUP"
    
    # Remove lines containing pam_touchid
    grep -v "pam_touchid" "$SUDO_LOCAL" > "$SUDO_LOCAL.tmp"
    mv "$SUDO_LOCAL.tmp" "$SUDO_LOCAL"
    
    # Remove sudo_local if it's now empty (except comments)
    if ! grep -q "^auth" "$SUDO_LOCAL" 2>/dev/null; then
        rm "$SUDO_LOCAL"
    fi
    
    echo "✓ Removed Touch ID from sudo"
fi

# Remove PAM module
rm -f "/usr/local/lib/pam/pam_touchid.so"
echo "✓ Uninstalled Touch ID for Sudo"
EOF

chmod +x "$WORK_DIR/payload/usr/local/bin/touchid-"*
log_success "Helper commands installed"
echo ""

# Step 7: Create distribution XML
log_info "Step 7: Creating installer configuration..."

cat > "$WORK_DIR/distribution.xml" << 'DISTXML'
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Touch ID for Sudo</title>
    <organization>vialyx</organization>
    <options allow-external-scripts="no" require-scripts="no"/>
    <domains enable_localSystem="true"/>
    <installation-check script="return true;"/>
    <volume-check script="return true;"/>
    <choices-outline>
        <line choice="install"/>
    </choices-outline>
    <choice id="install" title="Touch ID for Sudo" description="Enable Touch ID for sudo authentication">
        <pkg-ref id="com.vialyx.touchid-for-sudo"/>
    </choice>
    <pkg-ref id="com.vialyx.touchid-for-sudo" installKBytes="256" version="1.0.0" auth="Root">
        <relocate from="/" to="/"/>
    </pkg-ref>
</installer-gui-script>
DISTXML

log_success "Installer configuration created"
echo ""

# Step 8: Build component package
log_info "Step 8: Building component package..."

COMPONENT_PKG="/tmp/touchid-component.pkg"

pkgbuild \
    --root "$WORK_DIR/payload" \
    --scripts "$WORK_DIR/scripts" \
    --identifier "com.vialyx.touchid-for-sudo" \
    --version "$VERSION" \
    --ownership recommended \
    "$COMPONENT_PKG" || {
    log_error "Failed to build component package"
    exit 1
}

log_success "Component package built"
echo ""

# Step 9: Create resources
log_info "Step 9: Creating installer resources..."

mkdir -p "$WORK_DIR/resources"

cat > "$WORK_DIR/resources/LICENSE.txt" << 'EOF'
MIT License - Touch ID for Sudo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions.
EOF

cat > "$WORK_DIR/resources/README.txt" << 'EOF'
Touch ID for Sudo v1.0.0

Enable Touch ID authentication for sudo on macOS.

After installation:
  sudo touchid-configure

Test with:
  sudo whoami

Support: https://github.com/vialyx/touchid-for-sudo
EOF

log_success "Resources created"
echo ""

# Step 10: Create final package
log_info "Step 10: Creating final distribution package..."

# Simply copy the component package as the final product
# (productbuild with --component is tricky, just use the .pkg directly)
cp "$COMPONENT_PKG" "$PKG_FILE"

if [ ! -f "$PKG_FILE" ]; then
    log_error "Package file was not created"
    exit 1
fi

log_success "Distribution package created"
echo ""

# Step 11: Create checksum
log_info "Step 11: Creating checksum..."

SHA256_FILE="$PROJECT_DIR/$PKG_NAME.pkg.sha256"
shasum -a 256 "$PKG_FILE" > "$SHA256_FILE"

log_success "Checksum created"
echo ""

# Final summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PACKAGE CREATION COMPLETE ✓                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Package:"
echo "   File: $PKG_FILE"
echo "   Size: $(du -h "$PKG_FILE" | cut -f1)"
echo ""
echo "✓ Installation ready!"
echo "   Double-click to install or:"
echo "   open $PKG_FILE"
echo ""
