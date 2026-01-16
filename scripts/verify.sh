#!/bin/bash

#
# verify.sh - Verify Touch ID for Sudo works correctly
# Tests the installation and functionality
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

echo "Touch ID for Sudo - Verification Script"
echo "========================================"
echo ""

# Configuration
PAM_MODULE="/usr/local/lib/pam/pam_touchid.so"
SUDO_PAM="/etc/pam.d/sudo"

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Check if PAM module exists
log_info "Test 1: Checking if PAM module is installed..."
if [ -f "$PAM_MODULE" ]; then
    log_success "PAM module exists at $PAM_MODULE"
    ((TESTS_PASSED++))
else
    log_error "PAM module not found at $PAM_MODULE"
    ((TESTS_FAILED++))
fi

# Test 2: Check if PAM module is readable
if [ -f "$PAM_MODULE" ] && [ -r "$PAM_MODULE" ]; then
    log_success "PAM module is readable"
    ((TESTS_PASSED++))
else
    log_error "PAM module is not readable"
    ((TESTS_FAILED++))
fi

# Test 3: Check file permissions
if [ -f "$PAM_MODULE" ]; then
    PERMS=$(ls -l "$PAM_MODULE" | awk '{print $1}')
    log_info "PAM module permissions: $PERMS"
    ((TESTS_PASSED++))
fi

echo ""

# Test 4: Check sudo configuration
log_info "Test 2: Checking sudo PAM configuration..."
if grep -q "pam_touchid.so" "$SUDO_PAM"; then
    log_success "Touch ID is configured in sudo PAM"
    ((TESTS_PASSED++))
    
    # Show the configuration
    log_info "Touch ID configuration in sudo:"
    grep "pam_touchid.so" "$SUDO_PAM" | sed 's/^/    /'
else
    log_warning "Touch ID is NOT configured in sudo PAM"
    ((TESTS_FAILED++))
fi

echo ""

# Test 5: Check system compatibility
log_info "Test 3: Checking system compatibility..."
ARCH=$(uname -m)
MACOS_VERSION=$(sw_vers -productVersion)

log_info "Architecture: $ARCH"
log_info "macOS Version: $MACOS_VERSION"

if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "x86_64" ]; then
    log_success "Architecture is supported"
    ((TESTS_PASSED++))
else
    log_warning "Architecture may not be fully supported"
    ((TESTS_FAILED++))
fi

echo ""

# Test 6: Check for Touch ID support
log_info "Test 4: Checking for Touch ID support..."
if system_profiler SPUSBDataType | grep -q "Touch ID"; then
    log_success "Touch ID hardware detected"
    ((TESTS_PASSED++))
else
    log_warning "Touch ID hardware not detected (this is normal on some Mac models)"
    ((TESTS_FAILED++))
fi

echo ""

# Test 7: Test actual sudo with Touch ID
log_info "Test 5: Testing Touch ID with sudo..."
echo "Run the following command to test (you'll need to authenticate):"
echo "    sudo -v"
echo ""
log_info "If a Touch ID prompt appears, Touch ID is working correctly!"
log_info "If prompted for password instead, check configuration"

echo ""
echo "========================================"
echo "Verification Summary"
echo "========================================"
log_info "Tests Passed: $TESTS_PASSED"

if [ $TESTS_FAILED -eq 0 ]; then
    log_success "All tests passed! Touch ID for Sudo is properly installed."
else
    log_warning "Tests Failed: $TESTS_FAILED"
    log_info "Please check the installation with: ./scripts/status.sh"
fi

echo ""
