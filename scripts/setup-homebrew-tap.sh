#!/bin/bash

#
# setup-homebrew-tap.sh - Set up custom Homebrew tap
# Creates a Homebrew tap repository structure
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Homebrew Tap Setup - vialyx/touchid                         ║"
echo "║  Instructions for creating and publishing custom tap         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Create tap directory structure
TAP_DIR="$HOME/homebrew-touchid"

log_info "Creating Homebrew tap repository..."
mkdir -p "$TAP_DIR"
cd "$TAP_DIR"

# Initialize git if not already done
if [ ! -d .git ]; then
    git init
    git config user.email "you@example.com"
    git config user.name "Your Name"
fi

log_success "Created tap directory: $TAP_DIR"
echo ""

# Create directory structure
log_info "Creating directory structure..."
mkdir -p Formula
log_success "Created Formula directory"
echo ""

# Create formula
log_info "Creating Homebrew formula..."
cat > Formula/touchid-for-sudo.rb << 'EOF'
class TouchidForSudo < Formula
  desc "Enable Touch ID authentication for sudo on macOS"
  homepage "https://github.com/vialyx/touchid-for-sudo"
  url "https://github.com/vialyx/touchid-for-sudo/releases/download/v1.0.0/TouchID-for-Sudo-1.0.0.pkg"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  version "1.0.0"

  depends_on :macos => ">= :catalina"
  depends_on "xcode-select"

  def install
    # Download and extract the .pkg installer
    system "pkgutil", "--expand-full", cached_download, buildpath/"TouchID.pkg"
    
    # Install the PAM module
    lib.install "#{buildpath}/TouchID.pkg/Payload/usr/local/lib/pam/pam_touchid.so"
  end

  def post_install
    puts ""
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║  Touch ID for Sudo - Installation Complete!                 ║"
    puts "╚════════════════════════════════════════════════════════════════╝"
    puts ""
    puts "Next steps:"
    puts "  1. Run: sudo touchid-configure"
    puts "  2. Test: sudo whoami"
    puts "  3. Check status: touchid-status"
    puts ""
  end

  test do
    system "test", "-f", "#{lib}/pam_touchid.so"
  end
end
EOF

log_success "Created formula: Formula/touchid-for-sudo.rb"
echo ""

# Create README
log_info "Creating tap README..."
cat > README.md << 'EOF'
# Homebrew vialyx/touchid Tap

Custom Homebrew tap for Touch ID for Sudo and related tools.

## Usage

```bash
# Add this tap
brew tap vialyx/touchid

# Install Touch ID for Sudo
brew install touchid-for-sudo

# After installation, configure sudo
sudo touchid-configure

# Test with
sudo whoami

# Check status
touchid-status
```

## Uninstall

```bash
brew uninstall touchid-for-sudo
brew untap vialyx/touchid
```

## Requirements

- macOS 10.15 (Catalina) or later
- Mac with Touch ID support
- Xcode Command Line Tools

## Support

- [GitHub Issues](https://github.com/vialyx/touchid-for-sudo/issues)
- [Documentation](https://github.com/vialyx/touchid-for-sudo)

## License

MIT License
EOF

log_success "Created README.md"
echo ""

# Create .gitignore
log_info "Creating .gitignore..."
cat > .gitignore << 'EOF'
.DS_Store
*.swp
*.swo
*~
.env
EOF

log_success "Created .gitignore"
echo ""

# Show instructions
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  NEXT STEPS TO PUBLISH TAP                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Create GitHub Repository"
echo "   - Go to: https://github.com/new"
echo "   - Repository name: homebrew-touchid"
echo "   - Description: Homebrew tap for Touch ID for Sudo"
echo "   - Make it public"
echo ""
echo "2. Add Remote and Push"
echo "   cd $TAP_DIR"
echo "   git remote add origin https://github.com/YOUR_USERNAME/homebrew-touchid.git"
echo "   git add ."
echo "   git commit -m 'Initial commit: Touch ID for Sudo tap'"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Update SHA256"
echo "   - Get SHA256 from: TouchID-for-Sudo-1.0.0.pkg.sha256"
echo "   - Edit: $TAP_DIR/Formula/touchid-for-sudo.rb"
echo "   - Replace: REPLACE_WITH_ACTUAL_SHA256"
echo "   - Commit and push"
echo ""
echo "4. Test Installation"
echo "   brew tap YOUR_USERNAME/touchid $TAP_DIR"
echo "   brew install touchid-for-sudo"
echo "   sudo touchid-configure"
echo ""
echo "5. Users Can Install With"
echo "   brew tap YOUR_USERNAME/touchid"
echo "   brew install touchid-for-sudo"
echo ""
