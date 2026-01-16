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

# Remove PAM module reference from sudo config
if grep -q "pam_touchid.so" "$SUDO_PAM"; then
    log_info "Removing Touch ID from sudo configuration..."
    
    if [ -f "$SUDO_PAM_BACKUP" ]; then
        log_info "Restoring from backup..."
        cp "$SUDO_PAM_BACKUP" "$SUDO_PAM"
        log_success "Restored original sudo configuration from backup"
    else
        log_warning "Backup not found, manually removing pam_touchid.so from $SUDO_PAM"
        sed -i '' '/pam_touchid.so/d' "$SUDO_PAM"
        log_success "Removed pam_touchid.so reference"
    fi
else
    log_warning "Touch ID is not configured in sudo PAM"
fi

# Remove PAM module
if [ -f "$PAM_MODULE" ]; then
    rm -f "$PAM_MODULE"
    log_success "Removed PAM module from $PAM_MODULE"
else
    log_warning "PAM module not found at $PAM_MODULE"
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
