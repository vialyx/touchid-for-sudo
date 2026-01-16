#!/bin/bash

#
# github-release.sh - Create and publish GitHub release
# Prepares and publishes a release to GitHub
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
echo "║  Touch ID for Sudo - GitHub Release Preparation              ║"
echo "║  Prepares files and provides release instructions            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
VERSION="1.0.0"
GITHUB_REPO="YOUR_USERNAME/touchid-for-sudo"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

log_info "Preparing GitHub release for version $VERSION"
echo ""

# Check if git is initialized
if [ ! -d "$PROJECT_DIR/.git" ]; then
    log_error "Git repository not found. Please initialize git first:"
    echo "    cd $PROJECT_DIR"
    echo "    git init"
    echo "    git add ."
    echo "    git commit -m 'Initial commit: Touch ID for Sudo v$VERSION'"
    exit 1
fi

# Step 1: Create the .pkg installer
log_info "Step 1: Building .pkg installer..."
cd "$PROJECT_DIR"
bash build/package.sh > /dev/null 2>&1
PKG_FILE="$PROJECT_DIR/TouchID-for-Sudo-$VERSION.pkg"

if [ ! -f "$PKG_FILE" ]; then
    log_error "Failed to create .pkg installer"
    exit 1
fi

log_success ".pkg installer created: $(du -h "$PKG_FILE" | cut -f1)"
echo ""

# Step 2: Create checksums
log_info "Step 2: Creating checksums..."
SHA256_FILE="$PROJECT_DIR/TouchID-for-Sudo-$VERSION.pkg.sha256"
shasum -a 256 "$PKG_FILE" > "$SHA256_FILE"
log_success "Checksum created: $SHA256_FILE"
echo ""

# Step 3: Prepare release notes
log_info "Step 3: Preparing release notes..."
RELEASE_NOTES="$PROJECT_DIR/RELEASE_NOTES.md"
cat > "$RELEASE_NOTES" << 'EOF'
# Touch ID for Sudo v1.0.0

🎉 **Initial Release** - Enable Touch ID authentication for sudo on macOS!

## Features

- ✅ Use Touch ID instead of password for sudo
- ✅ One-click installation via .pkg
- ✅ Safe configuration with automatic backup
- ✅ Complete uninstallation support
- ✅ Works on Apple Silicon & Intel Macs
- ✅ macOS 10.15+ support

## Installation

### Option 1: Using .pkg (Easiest)
1. Download `TouchID-for-Sudo-1.0.0.pkg`
2. Double-click to open installer
3. Follow the wizard
4. Run: `sudo touchid-configure`
5. Done! Test with: `sudo whoami`

### Option 2: Using Homebrew
```bash
brew tap vialyx/touchid
brew install touchid-for-sudo
sudo touchid-configure
```

### Option 3: Build from Source
```bash
git clone https://github.com/vialyx/touchid-for-sudo.git
cd touchid-for-sudo
./scripts/install.sh
```

## Verification

After installation, verify everything works:
```bash
touchid-status
```

## Documentation

- [Quick Start Guide](QUICKSTART.md)
- [Detailed Installation](INSTALL.md)
- [Security Details](SECURITY.md)
- [Full README](README.md)

## Support

Having issues? Check the [Troubleshooting](README.md#troubleshooting) section.

## Donate

Love this tool? Support it with a donation:

[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=flat-square&logo=paypal)](https://paypal.me/vialyx)

## What's New

- Initial release
- PAM module for Touch ID authentication
- Professional .pkg installer
- One-click installation automation
- Comprehensive documentation
- Helper scripts included

## Requirements

- macOS 10.15 (Catalina) or later
- Mac with Touch ID support
- Xcode Command Line Tools (for building from source)

## SHA256 Checksum

```
SHA256: [See TouchID-for-Sudo-1.0.0.pkg.sha256]
```

## License

MIT License - See LICENSE file for details

---

**Enjoy Touch ID for sudo!** 🎊
EOF

log_success "Release notes created: $RELEASE_NOTES"
echo ""

# Step 4: Prepare GitHub release instructions
log_info "Step 4: Creating release instructions..."
RELEASE_INSTRUCTIONS="$PROJECT_DIR/GITHUB_RELEASE.md"
cat > "$RELEASE_INSTRUCTIONS" << 'EOF'
# GitHub Release Instructions

## Prerequisites

1. GitHub repository set up at: https://github.com/YOUR_USERNAME/touchid-for-sudo
2. Files prepared by `github-release.sh`
3. Git repository initialized and committed

## Step 1: Create Git Tag

```bash
cd /Users/maksimvialykh/github/touchid-for-sudo

# Create and push git tag
git tag -a v1.0.0 -m "Release v1.0.0: Touch ID for Sudo"
git push origin v1.0.0
```

## Step 2: Create GitHub Release

Go to: https://github.com/YOUR_USERNAME/touchid-for-sudo/releases/new

Fill in:
- **Tag**: v1.0.0
- **Release title**: Touch ID for Sudo v1.0.0
- **Description**: Copy from RELEASE_NOTES.md

## Step 3: Upload Assets

Attach these files to the release:

1. **TouchID-for-Sudo-1.0.0.pkg** (the installer)
2. **TouchID-for-Sudo-1.0.0.pkg.sha256** (checksum)
3. **README.md** (documentation)
4. **QUICKSTART.md** (quick start guide)

## Step 4: Publish Release

Click "Publish release" button.

## Step 5: Update Homebrew Cask

After GitHub release is published:

1. Submit cask to official Homebrew Cask repository
2. OR create your own tap: `vialyx/touchid`

See: `homebrew/Formula.rb` for cask details

## Verification

After release:

```bash
# Test GitHub download link
curl -L https://github.com/YOUR_USERNAME/touchid-for-sudo/releases/download/v1.0.0/TouchID-for-Sudo-1.0.0.pkg -o test.pkg

# Verify checksum
shasum -a 256 -c TouchID-for-Sudo-1.0.0.pkg.sha256
```

## Promotion

After release, promote it:

1. **Social Media**
   - Tweet/Post release announcement
   - Include PayPal donation link

2. **Communities**
   - Post to r/macadmins
   - Post to MacRumors forums
   - Share on Hacker News

3. **Directories**
   - ProductHunt
   - MacReleases
   - Awesome macOS repos

## Success Indicators

✅ Files prepared
✅ Git tag created
✅ GitHub release published
✅ Assets uploaded
✅ Homebrew cask available
✅ Users can install with: `brew install touchid-for-sudo`
EOF

log_success "Release instructions created: $RELEASE_INSTRUCTIONS"
echo ""

# Step 5: Show summary
log_info "Step 5: Release preparation summary"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  FILES READY FOR GITHUB RELEASE                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
log_success "TouchID-for-Sudo-$VERSION.pkg ($(du -h "$PKG_FILE" | cut -f1))"
log_success "TouchID-for-Sudo-$VERSION.pkg.sha256"
log_success "RELEASE_NOTES.md"
echo ""
echo "Next steps:"
echo "  1. Read: $RELEASE_INSTRUCTIONS"
echo "  2. Create git tag: git tag -a v$VERSION -m 'Release v$VERSION'"
echo "  3. Push tag: git push origin v$VERSION"
echo "  4. Create GitHub release with files"
echo "  5. Publish Homebrew cask"
echo ""
