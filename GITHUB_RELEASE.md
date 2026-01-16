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
