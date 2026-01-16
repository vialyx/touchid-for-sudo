#!/bin/bash

#
# install.sh - Complete installation script for Touch ID for Sudo
# Builds and installs the module, then configures sudo
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
echo "╔════════════════════════════════════════╗"
echo "║  Touch ID for Sudo - Installation      ║"
echo "║  macOS PAM Module                      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Project directory: $PROJECT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

# Step 1: Check prerequisites
log_info "Checking prerequisites..."

if ! command -v clang &> /dev/null; then
    log_error "clang not found. Please install Xcode Command Line Tools:"
    echo "    xcode-select --install"
    exit 1
fi
log_success "clang found"

if ! command -v make &> /dev/null; then
    log_error "make not found. Please install Xcode Command Line Tools"
    exit 1
fi
log_success "make found"

echo ""

# Step 2: Build the module
log_info "Building Touch ID PAM module..."
make clean > /dev/null 2>&1 || true
make build

echo ""

# Step 3: Install the module
log_info "Installing PAM module..."
log_warning "This step requires sudo privileges"
make install

echo ""

# Step 4: Configure sudo
log_info "Configuring sudo for Touch ID..."
log_warning "This step requires sudo privileges"

if [ -f "scripts/configure-sudo.sh" ]; then
    chmod +x "scripts/configure-sudo.sh"
    sudo bash "scripts/configure-sudo.sh"
else
    log_error "configure-sudo.sh not found"
    exit 1
fi

echo ""

# Step 5: Make scripts executable
log_info "Making helper scripts executable..."
chmod +x scripts/*.sh
log_success "Scripts are now executable"

echo ""

# Final status check
log_info "Installation summary:"
log_success "Touch ID for Sudo has been installed successfully!"
echo ""
log_info "Next steps:"
echo "    • Test: try using 'sudo' command in a new terminal"
echo "    • Status: ./scripts/status.sh"
echo "    • Uninstall: sudo ./scripts/uninstall.sh"
echo ""

if [ -f "scripts/status.sh" ]; then
    bash "scripts/status.sh"
fi

echo ""
