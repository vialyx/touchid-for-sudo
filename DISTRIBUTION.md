# Distribution Guide

Complete guide to distributing Touch ID for Sudo to GitHub and Homebrew.

## Quick Start

```bash
# Build .pkg installer
bash build/package.sh

# Prepare GitHub release
bash scripts/github-release.sh

# Set up Homebrew tap
bash scripts/setup-homebrew-tap.sh
```

## Part 1: GitHub Releases

### Step 1: Prepare GitHub Repository

If you haven't already set up GitHub:

```bash
cd /Users/maksimvialykh/github/touchid-for-sudo

# Initialize git (if not done)
git init

# Add files
git add .
git commit -m "Initial commit: Touch ID for Sudo v1.0.0"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/touchid-for-sudo.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 2: Build Release Artifacts

```bash
# Build the .pkg installer
bash build/package.sh

# This creates:
# - TouchID-for-Sudo-1.0.0.pkg (the installer)
# - TouchID-for-Sudo-1.0.0.pkg.sha256 (checksum)
```

### Step 3: Prepare Release

```bash
# Prepare release files and instructions
bash scripts/github-release.sh

# This creates:
# - RELEASE_NOTES.md
# - GITHUB_RELEASE.md (with detailed instructions)
```

### Step 4: Create GitHub Release

1. Go to: https://github.com/YOUR_USERNAME/touchid-for-sudo/releases/new

2. Create the release:
   ```
   Tag: v1.0.0
   Title: Touch ID for Sudo v1.0.0
   Description: [Copy from RELEASE_NOTES.md]
   ```

3. Upload release assets:
   - TouchID-for-Sudo-1.0.0.pkg
   - TouchID-for-Sudo-1.0.0.pkg.sha256
   - README.md
   - QUICKSTART.md
   - SECURITY.md (optional)

4. Click "Publish release"

### Step 5: Verify Release

Users can verify the release with:

```bash
# Download installer
curl -L https://github.com/YOUR_USERNAME/touchid-for-sudo/releases/download/v1.0.0/TouchID-for-Sudo-1.0.0.pkg -o TouchID-for-Sudo-1.0.0.pkg

# Verify checksum
shasum -a 256 -c TouchID-for-Sudo-1.0.0.pkg.sha256
```

## Part 2: Homebrew Distribution

### Option A: Create Custom Tap (Recommended)

A custom tap is a Homebrew repository you control.

#### Step 1: Set Up Tap Repository

```bash
bash scripts/setup-homebrew-tap.sh
```

This creates directory structure:
```
~/homebrew-touchid/
├── Formula/
│   └── touchid-for-sudo.rb
├── README.md
└── .gitignore
```

#### Step 2: Create GitHub Repository for Tap

1. Go to: https://github.com/new
   - Repository name: `homebrew-touchid`
   - Description: "Homebrew tap for Touch ID for Sudo"
   - Make it **public**

2. Push the tap repository:

```bash
cd ~/homebrew-touchid
git remote add origin https://github.com/YOUR_USERNAME/homebrew-touchid.git
git add .
git commit -m "Initial commit: Touch ID for Sudo tap"
git branch -M main
git push -u origin main
```

#### Step 3: Update SHA256 in Formula

1. Get the SHA256:
   ```bash
   cat /Users/maksimvialykh/github/touchid-for-sudo/TouchID-for-Sudo-1.0.0.pkg.sha256
   # Output: abc123... TouchID-for-Sudo-1.0.0.pkg
   ```

2. Update formula:
   ```bash
   # Edit ~/homebrew-touchid/Formula/touchid-for-sudo.rb
   # Replace: sha256 "YOUR_SHA256_HERE"
   # With the actual SHA256 from step 1
   ```

3. Commit and push:
   ```bash
   cd ~/homebrew-touchid
   git add Formula/touchid-for-sudo.rb
   git commit -m "Update SHA256 for v1.0.0"
   git push
   ```

#### Step 4: Users Can Install

```bash
# Add your tap
brew tap YOUR_USERNAME/touchid

# Install
brew install touchid-for-sudo

# Configure
sudo touchid-configure

# Test
sudo whoami
```

### Option B: Submit to Official Homebrew

Submit directly to Homebrew's official repository (no custom tap needed).

#### Step 1: Fork Homebrew Core

Go to: https://github.com/Homebrew/homebrew-core

#### Step 2: Add Formula

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/homebrew-core.git
   cd homebrew-core
   ```

2. Create formula:
   ```bash
   # Copy from: /Users/maksimvialykh/github/touchid-for-sudo/homebrew/Formula.rb
   # To: Formula/touchid-for-sudo.rb
   
   cp /Users/maksimvialykh/github/touchid-for-sudo/homebrew/Formula.rb \
      Formula/touchid-for-sudo.rb
   ```

3. Update SHA256:
   ```bash
   # Edit Formula/touchid-for-sudo.rb
   # Replace SHA256 with actual value
   ```

#### Step 3: Test Formula

```bash
brew audit --new-formula Formula/touchid-for-sudo.rb
brew install --build-from-source Formula/touchid-for-sudo.rb
```

#### Step 4: Create Pull Request

1. Push to your fork:
   ```bash
   git add Formula/touchid-for-sudo.rb
   git commit -m "Add touchid-for-sudo formula"
   git push
   ```

2. Go to: https://github.com/Homebrew/homebrew-core/compare
   - Create PR from your fork
   - Fill in template
   - Wait for review/approval

**Note:** Official Homebrew takes longer but reaches more users.

## Installation Methods Summary

After distribution setup, users can install via:

### Method 1: Direct Download from GitHub
```bash
# Download .pkg
# Double-click to install
```

### Method 2: Custom Homebrew Tap
```bash
brew tap YOUR_USERNAME/touchid
brew install touchid-for-sudo
```

### Method 3: Official Homebrew (if accepted)
```bash
brew install touchid-for-sudo
```

### Method 4: Build from Source
```bash
git clone https://github.com/YOUR_USERNAME/touchid-for-sudo.git
cd touchid-for-sudo
./scripts/install.sh
```

## Promotion

After releasing, promote it:

### Social Media
- Twitter/X: Share release with PayPal link
- LinkedIn: Post about macOS security enhancement
- Reddit: Post to r/macadmins, r/MacOS

### Communities
- MacRumors forums
- Hacker News (Show HN)
- ProductHunt
- Awesome macOS repos (submit PR)

### Documentation
- Blog post about Touch ID + sudo
- Tutorial: "How to use Touch ID with sudo"
- Video demo (optional)

### Monetization
Include PayPal donation link: https://paypal.me/vialyx

```markdown
[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=flat-square&logo=paypal)](https://paypal.me/vialyx)
```

## Distribution Checklist

- [ ] GitHub repository created and initialized
- [ ] Git history clean and well-documented
- [ ] .pkg installer builds successfully
- [ ] SHA256 checksum verified
- [ ] Release notes prepared
- [ ] GitHub release created with assets
- [ ] Custom Homebrew tap set up (or official PR submitted)
- [ ] Homebrew formula tested
- [ ] Installation methods documented
- [ ] Promotion plan executed
- [ ] Users can successfully install and use

## Troubleshooting

### Homebrew Formula Not Installing

```bash
# Check formula syntax
brew audit --new-formula Formula/touchid-for-sudo.rb

# Install with verbose output
brew install -v touchid-for-sudo

# Check installation
brew list touchid-for-sudo
```

### GitHub Release Download Failed

```bash
# Verify URL works
curl -L https://github.com/YOUR_USERNAME/touchid-for-sudo/releases/download/v1.0.0/TouchID-for-Sudo-1.0.0.pkg -I

# Check file integrity
shasum -a 256 -c TouchID-for-Sudo-1.0.0.pkg.sha256
```

### Users Can't Find on Homebrew

- Ensure tap is properly public on GitHub
- Check formula is in `Formula/` directory (not `Formulae/`)
- Update tap metadata if needed
- Test with: `brew tap YOUR_USERNAME/touchid`

## Version Updates

For future releases:

```bash
# Update version numbers
# Rebuild .pkg: bash build/package.sh
# Create release: bash scripts/github-release.sh
# Update Homebrew: Update SHA256 and version
# Create GitHub release with new assets
# Push Homebrew changes
```

## Questions?

- [GitHub Issues](https://github.com/YOUR_USERNAME/touchid-for-sudo/issues)
- [Homebrew FAQ](https://docs.brew.sh/FAQ)
- [GitHub Releases Help](https://docs.github.com/en/repositories/releasing-projects-on-github/)

---

**Ready to distribute?** Start with `bash scripts/github-release.sh` 🚀
