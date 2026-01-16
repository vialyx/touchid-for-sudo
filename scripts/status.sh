#!/bin/bash

#
# status.sh - Check Touch ID for Sudo status
# Shows whether Touch ID is configured and working
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
PAM_MODULE="/usr/local/lib/pam/pam_touchid.so"
SUDO_PAM="/etc/pam.d/sudo"

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

echo "Touch ID for Sudo - Status Check"
echo "================================"
echo ""

# Check if PAM module exists
if [ -f "$PAM_MODULE" ]; then
    log_success "PAM module installed"
    ls -lh "$PAM_MODULE" | awk '{print "  Size: " $5 ", Modified: " $6 " " $7 " " $8}'
else
    log_error "PAM module not found at $PAM_MODULE"
fi

echo ""

# Check if configured in sudo
if grep -q "pam_touchid.so" "$SUDO_PAM"; then
    log_success "Touch ID configured for sudo"
    log_info "Configuration:"
    grep "pam_touchid.so" "$SUDO_PAM" | sed 's/^/    /'
else
    log_warning "Touch ID not configured for sudo"
fi

echo ""

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
log_info "macOS Version: $MACOS_VERSION"

# Check architecture
ARCH=$(uname -m)
log_info "Architecture: $ARCH"

# Check if Touch ID is available on this Mac
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "x86_64" ]; then
    log_success "Architecture supports Touch ID"
else
    log_warning "Architecture may not support Touch ID"
fi

echo ""
log_info "To enable Touch ID for sudo, run:"
echo "    sudo ./scripts/configure-sudo.sh"
echo ""
