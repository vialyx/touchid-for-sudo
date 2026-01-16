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

# Backup existing sudo PAM config
if [ ! -f "$SUDO_PAM_BACKUP" ]; then
    log_info "Backing up original sudo PAM configuration..."
    cp "$SUDO_PAM" "$SUDO_PAM_BACKUP"
    log_success "Backup saved to $SUDO_PAM_BACKUP"
else
    log_warning "Backup already exists at $SUDO_PAM_BACKUP"
fi

# Check if already configured
if grep -q "pam_touchid.so" "$SUDO_PAM"; then
    log_warning "Touch ID is already configured for sudo"
    exit 0
fi

# Get the current auth line (usually first auth line)
FIRST_AUTH_LINE=$(grep -n "^auth" "$SUDO_PAM" | head -1 | cut -d: -f1)

if [ -z "$FIRST_AUTH_LINE" ]; then
    log_error "Could not find auth configuration in $SUDO_PAM"
    exit 1
fi

# Create temporary file with new config
TEMP_FILE=$(mktemp)

# Insert Touch ID module before the first auth line
head -n $((FIRST_AUTH_LINE - 1)) "$SUDO_PAM" > "$TEMP_FILE"
echo "auth       optional       $PAM_MODULE" >> "$TEMP_FILE"
tail -n +$FIRST_AUTH_LINE "$SUDO_PAM" >> "$TEMP_FILE"

# Replace the original file
cp "$TEMP_FILE" "$SUDO_PAM"
rm "$TEMP_FILE"

log_success "sudo PAM configuration updated successfully!"
log_info "Touch ID is now enabled for sudo authentication"
log_warning "Note: You may need to restart Terminal or your session for changes to take effect"

# Show current configuration
log_info "Current sudo PAM configuration:"
echo ""
grep -n "^auth" "$SUDO_PAM" | head -5
echo ""
