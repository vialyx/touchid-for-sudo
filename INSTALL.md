# Installation Guide

## Prerequisites

Before installing Touch ID for Sudo, ensure you have:

### System Requirements
- **macOS**: 10.15 (Catalina) or later
- **Processor**: Apple Silicon (ARM64) or Intel (x86_64)
- **Touch ID**: Compatible Mac with Touch ID support
  - MacBook Pro with Touch Bar (2015 or later)
  - MacBook Air (M1 or later)
  - Mac mini (M1 or later)
  - iMac (M1 or later)
  - Mac Studio

### Software Requirements
- **Xcode Command Line Tools** - Required for compilation
- **Terminal** or other shell
- **Administrator Access** - Needed for installation

### Check Your Mac

**Check macOS Version:**
```bash
sw_vers -productVersion
# Should output 10.15 or higher
```

**Check Architecture:**
```bash
uname -m
# Should output 'arm64' or 'x86_64'
```

**Check for Touch ID:**
```bash
system_profiler SPUSBDataType | grep "Touch ID"
# Should show Touch ID device
```

## Installation Steps

### Step 1: Install Xcode Command Line Tools

If not already installed:

```bash
xcode-select --install
```

A window will appear asking to install. Click "Install" and wait for completion.

**Verify installation:**
```bash
clang --version
# Should show a version number
```

### Step 2: Clone the Repository

```bash
# Navigate to your preferred location
cd ~/projects  # or your preferred directory

# Clone the repository
git clone https://github.com/maksimvialykh/touchid-for-sudo.git
cd touchid-for-sudo
```

### Step 3: Run the Installer

```bash
# Make the installer executable
chmod +x scripts/install.sh

# Run the automated installer
./scripts/install.sh
```

The installer will:
1. ✓ Check for Xcode Command Line Tools
2. ✓ Build the PAM module
3. ✓ Install it to `/usr/local/lib/pam/pam_touchid.so`
4. ✓ Configure sudo to use Touch ID (may ask for password)
5. ✓ Display status

### Step 4: Restart Terminal

Close and reopen Terminal.app or start a new terminal session.

### Step 5: Test Installation

Try using sudo with Touch ID:

```bash
sudo whoami
```

You should see a Touch ID prompt. Authenticate using your fingerprint.

## Manual Installation

If you prefer to install step-by-step:

### Step 1: Build

```bash
make build
```

This creates `build/pam_touchid.so`

### Step 2: Install Module

```bash
make install
```

Installs the module to `/usr/local/lib/pam/pam_touchid.so`

### Step 3: Configure Sudo

```bash
sudo ./scripts/configure-sudo.sh
```

This modifies `/etc/pam.d/sudo` to use Touch ID.

### Step 4: Verify

```bash
./scripts/status.sh
```

## Troubleshooting Installation

### "Command not found: clang"

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Permission denied" on scripts

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Build fails with framework errors

Ensure Xcode Command Line Tools are fully installed:
```bash
xcode-select --reset
xcode-select --install
```

### Installation completes but Touch ID doesn't work

1. **Restart Terminal**
   - Close all Terminal windows
   - Open a new Terminal

2. **Verify installation**
   ```bash
   ./scripts/status.sh
   ```

3. **Check configuration**
   ```bash
   grep pam_touchid /etc/pam.d/sudo
   ```

4. **Review system logs**
   ```bash
   log stream --predicate 'eventMessage contains "pam_touchid"' --level debug
   ```

### "Permission denied" when running install.sh

The script needs permission to modify system files. When prompted, enter your password or allow via Touch ID.

## Post-Installation

### Verify Installation

Run the verification script:
```bash
./scripts/verify.sh
```

This checks:
- ✓ PAM module installation
- ✓ Sudo configuration
- ✓ System compatibility
- ✓ Touch ID hardware

### First Use

Try the following commands to test:

```bash
# Simple test
sudo whoami

# Another test
sudo ls /root

# Validate sudo session
sudo -v
```

### Optional: Change to Required Mode

By default, Touch ID is optional (password is available as fallback).

To make Touch ID required, edit `/etc/pam.d/sudo`:

```bash
# View current configuration
grep pam_touchid /etc/pam.d/sudo
# Shows: auth       optional       /usr/local/lib/pam/pam_touchid.so

# To change to required mode, edit as root
sudo nano /etc/pam.d/sudo
# Change 'optional' to 'required'

# The line should now read:
# auth       required       /usr/local/lib/pam/pam_touchid.so
```

**⚠️ Warning**: Using `required` means you must use Touch ID to use sudo. If Touch ID fails, you cannot use sudo at all. Only do this if you're certain it will work on your Mac.

## Uninstallation

To remove Touch ID for Sudo:

```bash
sudo ./scripts/uninstall.sh
```

This will:
1. Remove the PAM module
2. Restore the original sudo configuration (from backup)
3. Ask if you want to remove the backup file

Your original sudo configuration is automatically restored.

## Configuration File Locations

After installation, the following files are created:

```
/usr/local/lib/pam/pam_touchid.so          # PAM module
/etc/pam.d/sudo                             # Modified (with backup)
/etc/pam.d/sudo.backup.touchid              # Backup of original
```

## Command Reference

### Useful Commands

```bash
# Check status
./scripts/status.sh

# Verify installation
./scripts/verify.sh

# Check logs
log stream --predicate 'eventMessage contains "pam_touchid"' --level debug

# Test sudo
sudo whoami
sudo ls
sudo -v

# Validate system
system_profiler SPUSBDataType | grep "Touch ID"
```

### Make Commands

```bash
make build       # Compile the module
make install     # Install the module
make uninstall   # Remove the module
make clean       # Remove build artifacts
make help        # Show available commands
```

## Backup and Recovery

### Original Configuration Backup

When you install Touch ID for Sudo, the original sudo PAM configuration is automatically backed up to:

```
/etc/pam.d/sudo.backup.touchid
```

If something goes wrong, you can manually restore it:

```bash
sudo cp /etc/pam.d/sudo.backup.touchid /etc/pam.d/sudo
```

### Complete Uninstallation

To completely remove Touch ID for Sudo:

```bash
sudo ./scripts/uninstall.sh
```

This safely removes everything and restores your original configuration.

## Support

Having issues? 

1. **Check the README**
   - Full documentation with troubleshooting

2. **Check the Quick Start Guide**
   - QUICKSTART.md for basic help

3. **Review System Logs**
   ```bash
   log stream --predicate 'eventMessage contains "pam_touchid"' --level debug
   ```

4. **Run Status Check**
   ```bash
   ./scripts/status.sh
   ```

5. **Open a GitHub Issue**
   - Include your macOS version, Mac model, and error messages

## Next Steps

After successful installation:

1. **Read the README** for detailed usage
2. **Check SECURITY.md** for security details
3. **Review CONTRIBUTING.md** if you want to contribute
4. **Consider supporting the project** - PayPal link in README

---

**Installation Complete!** Enjoy Touch ID authentication for sudo! 🎉
