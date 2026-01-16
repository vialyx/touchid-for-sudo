#!/bin/bash

#
# uninstall.sh - Uninstall Touch ID for Sudo
# Removes PAM module and restores original sudo configuration
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

log_info "Uninstalling Touch ID for Sudo..."

# Remove from sudo_local (modern macOS approach)
SUDO_LOCAL="/etc/pam.d/sudo_local"
SUDO_LOCAL_BACKUP="/etc/pam.d/sudo_local.backup.touchid"

if grep -q "pam_touchid.so" "$SUDO_LOCAL" 2>/dev/null; then
    log_info "Removing Touch ID from $SUDO_LOCAL..."
    
    # Backup current state
    cp "$SUDO_LOCAL" "$SUDO_LOCAL_BACKUP"
    
    # Remove lines containing pam_touchid
    grep -v "pam_touchid" "$SUDO_LOCAL" > "$SUDO_LOCAL.tmp"
    mv "$SUDO_LOCAL.tmp" "$SUDO_LOCAL"
    
    # Remove sudo_local if it's now empty
    if ! grep -q "^auth" "$SUDO_LOCAL" 2>/dev/null; then
        rm "$SUDO_LOCAL"
        log_success "Removed $SUDO_LOCAL (was empty after removing Touch ID)"
    else
        log_success "Removed Touch ID from $SUDO_LOCAL"
    fi
else
    log_warning "Touch ID is not configured in $SUDO_LOCAL"
fi

# Remove PAM module
if [ -f "$PAM_MODULE" ]; then
    rm -f "$PAM_MODULE"
    log_success "Removed PAM module from $PAM_MODULE"
else
    log_warning "PAM module not found at $PAM_MODULE"
fi

# Remove helper binary
HELPER_BIN="/usr/local/bin/touchid-helper"
if [ -f "$HELPER_BIN" ]; then
    rm -f "$HELPER_BIN"
    log_success "Removed helper from $HELPER_BIN"
else
    log_warning "Helper not found at $HELPER_BIN"
fi

# Clean backups
if [ -f "$SUDO_PAM_BACKUP" ]; then
    read -p "Remove backup file? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$SUDO_PAM_BACKUP"
        log_success "Backup removed"
    fi
fi

log_success "Uninstallation complete!"
