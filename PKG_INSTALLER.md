# Creating and Installing the .pkg File

## For End Users: Installing from .pkg

### Step 1: Download the Installer
Download `TouchID-for-Sudo-1.0.0.pkg` from GitHub releases.

### Step 2: Run the Installer
1. Double-click the `.pkg` file
2. The macOS installer will open
3. Click "Continue" through the installer screens
4. When prompted, enter your Mac password
5. Click "Install"
6. Wait for installation to complete

### Step 3: Configure Sudo (Required)
After installation, open Terminal and run:

```bash
sudo touchid-configure
```

Enter your password when prompted. This configures sudo to use Touch ID.

### Step 4: Test It
Try using sudo with Touch ID:

```bash
sudo whoami
```

You should see a Touch ID prompt. Authenticate with your fingerprint!

## For Developers: Creating the .pkg

### Build the Package

From the project root directory:

```bash
bash build/package.sh
```

This will:
1. ✓ Check for Xcode Command Line Tools
2. ✓ Build the PAM module
3. ✓ Create package structure
4. ✓ Include all necessary files
5. ✓ Generate `TouchID-for-Sudo-1.0.0.pkg`

### What's Inside the .pkg

The installer includes:
- **PAM Module** - `/usr/local/lib/pam/pam_touchid.so`
- **Helper Scripts**:
  - `touchid-configure` - Set up Touch ID for sudo
  - `touchid-status` - Check installation status
  - `touchid-uninstall` - Remove Touch ID for sudo
- **Documentation** - README and Quick Start guide
- **Post-Installation Script** - Provides setup instructions

### Package Features

✅ **Professional UI** - Branded installer with system checks
✅ **Pre-flight Checks** - Verifies Touch ID support
✅ **Post-installation Guide** - Clear setup instructions
✅ **Helper Commands** - Easy-to-use tools included
✅ **Documentation** - Full docs included in package
✅ **Standard Installation** - Uses macOS native installer

## Installing from Command Line

You can also install the .pkg from Terminal:

```bash
sudo installer -pkg TouchID-for-Sudo-1.0.0.pkg -target /
```

Or drag-and-drop style:

```bash
open TouchID-for-Sudo-1.0.0.pkg
```

## Uninstalling

After installation, you have two options:

### Option 1: Using Included Script
```bash
sudo touchid-uninstall
```

This removes the PAM module and restores your original sudo configuration.

### Option 2: Manual Removal
```bash
# Remove the PAM module
sudo rm /usr/local/lib/pam/pam_touchid.so

# Restore original sudo config from backup
sudo cp /etc/pam.d/sudo.backup.touchid /etc/pam.d/sudo

# Remove helper scripts (optional)
rm /usr/local/bin/touchid-*
```

## Distribution

### Share the .pkg File

1. **GitHub Releases**
   - Upload to GitHub releases
   - Include release notes from CHANGELOG.md
   - Make it easy for users to find

2. **Homebrew Cask**
   Create a cask formula for automatic installation:
   ```bash
   brew install touchid-for-sudo
   ```

3. **Direct Download**
   - Host on your website
   - Include installation instructions

### Installation Statistics

After distribution, users will see:
- **Installer Size**: ~500 KB
- **Installation Time**: < 30 seconds
- **Required Disk Space**: < 1 MB
- **Requires**: macOS 10.15+, Touch ID hardware

## Troubleshooting .pkg Installation

### "Cannot verify developer" error

If you see this error, follow these steps:

1. Right-click the `.pkg` file
2. Select "Open"
3. Click "Open" in the dialog
4. Enter your password if prompted

Alternatively, temporarily disable Gatekeeper:

```bash
sudo spctl --master-disable
# Then install the package
sudo spctl --master-enable
```

### Installation fails with "destination not available"

Ensure you have write permissions to `/usr/local/lib/pam`:

```bash
ls -la /usr/local/lib/
```

If the directory doesn't exist:

```bash
sudo mkdir -p /usr/local/lib/pam
sudo chmod 755 /usr/local/lib/pam
```

### "Post-installation script failed"

This usually means `sudo touchid-configure` failed. After the installer completes:

1. Open Terminal
2. Run: `sudo touchid-configure` manually
3. Follow the prompts

## Building for Distribution

### Prerequisites

```bash
# Ensure you have Xcode Command Line Tools
xcode-select --install

# Verify pkgbuild is available
pkgbuild --version
```

### Build Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/touchid-for-sudo.git
   cd touchid-for-sudo
   ```

2. **Create the package**
   ```bash
   bash build/package.sh
   ```

3. **Verify the package**
   ```bash
   ls -lh TouchID-for-Sudo-*.pkg
   ```

4. **Test the package** (optional)
   ```bash
   # Test in a VM or separate account first
   sudo installer -pkg TouchID-for-Sudo-1.0.0.pkg -target /
   ```

### Signing the Package (Optional but Recommended)

For production distribution, sign the package:

```bash
# Create or import a signing certificate
# Then sign the package
productsign --sign "Developer ID Installer" \
  TouchID-for-Sudo-1.0.0.pkg \
  TouchID-for-Sudo-1.0.0-signed.pkg
```

## Package Contents Breakdown

```
TouchID-for-Sudo-1.0.0.pkg/
├── Contents/
│   ├── PkgInfo
│   ├── Resources/
│   │   ├── README.md
│   │   └── QUICKSTART.md
│   ├── Packages/
│   │   └── TouchID-for-Sudo-component.pkg
│   │       ├── Contents/
│   │       │   ├── Archive.pax.gz
│   │       │   │   └── usr/
│   │       │   │       ├── local/lib/pam/pam_touchid.so
│   │       │   │       └── local/bin/
│   │       │   │           ├── touchid-configure
│   │       │   │           ├── touchid-status
│   │       │   │           └── touchid-uninstall
│   │       │   ├── Scripts/
│   │       │   │   ├── preinstall
│   │       │   │   └── postinstall
│   │       │   └── PackageInfo
│   │       └── Scripts/
│   │           ├── preinstall
│   │           └── postinstall
│   └── distribution.xml
```

## After Installation

### First-Time Setup

1. **Open Terminal** (or iTerm2)
2. **Run configuration**:
   ```bash
   sudo touchid-configure
   ```
3. **Verify installation**:
   ```bash
   touchid-status
   ```
4. **Test Touch ID**:
   ```bash
   sudo whoami
   ```

### Helpful Commands

```bash
# Check installation status
touchid-status

# Reconfigure sudo
sudo touchid-configure

# Remove Touch ID for Sudo
sudo touchid-uninstall

# View help
man pam_touchid
```

## Support

Having issues with the .pkg installer?

1. **Check the README**: [README.md](../README.md)
2. **Review installation logs**: 
   ```bash
   log stream --predicate 'eventMessage contains "touchid"'
   ```
3. **Run verification**:
   ```bash
   touchid-status
   ```
4. **Open a GitHub issue** with the error message

---

**The .pkg installer makes Touch ID for Sudo accessible to all Mac users!**
