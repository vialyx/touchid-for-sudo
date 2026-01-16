#!/bin/bash

#
# configure-sudo.sh - Configure sudo to use Touch ID PAM module
# This script modifies /etc/pam.d/sudo to enable Touch ID authentication
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
SUDO_PAM_BACKUP="/etc/pam.d/sudo.backup.touchid"

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run with sudo"
    exit 1
fi

# Check if PAM module exists
if [ ! -f "$PAM_MODULE" ]; then
    log_error "PAM module not found at $PAM_MODULE"
    log_info "Please run 'make install' first"
    exit 1
fi

log_info "Configuring sudo to use Touch ID..."

# Modern macOS uses /etc/pam.d/sudo_local for local customizations
SUDO_LOCAL="/etc/pam.d/sudo_local"

# Check if already configured
if grep -q "pam_touchid.so" "$SUDO_LOCAL" 2>/dev/null; then
    log_warning "Touch ID is already configured for sudo"
    exit 0
fi

if [ ! -f "$SUDO_LOCAL" ]; then
    # Create new sudo_local
    log_info "Creating $SUDO_LOCAL for Touch ID..."
    {
        echo "# Touch ID for Sudo - local customization for sudo PAM"
        echo "auth       sufficient     $PAM_MODULE"
    } > "$SUDO_LOCAL"
    chmod 644 "$SUDO_LOCAL"
    log_success "Created $SUDO_LOCAL"
else
    # Add Touch ID to existing sudo_local
    log_info "Adding Touch ID to existing $SUDO_LOCAL..."
    
    if [ ! -f "$SUDO_PAM_BACKUP" ]; then
        cp "$SUDO_LOCAL" "$SUDO_PAM_BACKUP"
    fi
    
    {
        echo "# Touch ID for Sudo - added by configure script"
        echo "auth       sufficient     $PAM_MODULE"
        cat "$SUDO_LOCAL"
    } > "$SUDO_LOCAL.tmp"
    
    mv "$SUDO_LOCAL.tmp" "$SUDO_LOCAL"
    chmod 644 "$SUDO_LOCAL"
    log_success "Updated $SUDO_LOCAL"
fi

# Verify configuration
if grep -q "pam_touchid.so" "$SUDO_LOCAL"; then
    log_success "Touch ID is now enabled for sudo authentication!"
    echo ""
    log_info "Current sudo_local configuration:"
    echo ""
    cat "$SUDO_LOCAL"
    echo ""
else
    log_error "Configuration failed!"
    exit 1
fi
