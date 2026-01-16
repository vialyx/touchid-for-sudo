# Touch ID for Sudo

> **Support This Project**
> [![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=flat-square&logo=paypal)](https://paypal.me/vialyx) - If this tool helps you, please consider making a donation!

[![GitHub Release](https://img.shields.io/github/v/release/vialyx/touchid-for-sudo?style=flat-square)](https://github.com/vialyx/touchid-for-sudo/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![macOS Support](https://img.shields.io/badge/macOS-10.15%2B-blue?style=flat-square)](README.md)
[![Status: Production](https://img.shields.io/badge/Status-Production%20Ready-green?style=flat-square)](README.md)

Enable biometric Touch ID authentication for `sudo` on macOS. This project provides a two-component architecture with a PAM module and user-space helper that allows you to use your Mac's Touch ID instead of typing your password for sudo commands.

## 📦 Quick Installation (Recommended)

### Download & Install from Release

The easiest way to get started - no compilation needed:

1. **Download** the latest `.pkg` installer from [Releases](https://github.com/vialyx/touchid-for-sudo/releases)
2. **Double-click** `TouchID-for-Sudo-1.0.0.pkg`
3. **Follow** the installer prompts
4. **Done!** Touch ID is now configured for sudo

That's it! No manual steps required. The installer automatically sets up everything.

### Verify Installation

```bash
sudo touchid-status
# Expected output: ✓ Sudo configured for Touch ID
```

### First Use

```bash
sudo whoami
# Touch ID prompt appears on your Mac
# Scan your fingerprint
root
```

---

## Features

- ✅ **Biometric Authentication**: Use Touch ID for sudo instead of typing passwords
- ✅ **User-Space Architecture**: Helper runs as user for proper biometric access
- ✅ **Secure IPC**: Unix domain socket communication (0600 permissions)
- ✅ **Password Fallback**: Cancel Touch ID to use password (when needed)
- ✅ **macOS Native**: Uses Apple's LocalAuthentication framework
- ✅ **Seamless Installation**: One-click .pkg installer or automated setup
- ✅ **Full Uninstall**: Completely reversible
- ✅ **Apple Silicon & Intel**: Works on both ARM64 and x86_64 Macs
- ✅ **Production Ready**: Comprehensive testing and documentation
- ✅ **Logging**: System logging for debugging

## Requirements

- macOS 10.15 (Catalina) or later
- Mac with Touch ID support (MacBook Pro with Touch Bar, MacBook Air M1+, etc.)
- Administrator access (sudo)

Optional (for building from source):
- Xcode Command Line Tools
- Make/Clang

## Installation

### Option 1: Pre-Built Package (Easiest) ⭐

```bash
# Download from Releases page and double-click
open TouchID-for-Sudo-1.0.0.pkg
```

**Features of the .pkg installer:**
- ✓ One-click installation
- ✓ Automatic configuration
- ✓ No manual setup required
- ✓ Easy uninstallation via script

### Option 2: Build from Source

#### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

#### Quick Start

```bash
git clone https://github.com/vialyx/touchid-for-sudo.git
cd touchid-for-sudo
make build
sudo make install
sudo ./scripts/configure-sudo.sh
```

#### Manual Installation

```bash
# Build the PAM module and helper
make build

# Install both components (requires sudo)
make install

# Configure sudo for Touch ID (requires sudo)
sudo ./scripts/configure-sudo.sh
```

## Usage

After installation, simply use `sudo` as normal:

```bash
sudo whoami
```

Instead of typing your password, you'll be prompted to authenticate with Touch ID. Swipe your finger on the Touch ID sensor to authenticate.

### Testing

Verify the installation:

```bash
./scripts/status.sh
```

### Configuration

The module is configured by default to be optional - if Touch ID fails, you'll be prompted for a password.

To change this behavior, edit `/etc/pam.d/sudo` and change:
```
auth       optional       /usr/local/lib/pam/pam_touchid.so
```

To:
```
auth       required       /usr/local/lib/pam/pam_touchid.so
```

⚠️ **Warning**: Using `required` means Touch ID authentication must succeed, you won't have a password fallback. Use with caution.

## Uninstallation

### From Package (Easiest)

If you installed from the `.pkg`, use:

```bash
sudo touchid-uninstall
```

This will:
- Remove PAM module
- Remove helper binary
- Clean up PAM configuration
- No restart required

### From Source

```bash
sudo make uninstall
```

Then optionally:

```bash
sudo touchid-uninstall
```

Everything is completely reversible.

## How It Works

### Architecture Overview

Touch ID for Sudo uses a **two-component architecture** to properly handle biometric authentication:

```
User runs: sudo whoami
    ↓
[PAM Module - pam_touchid.so] (running as root)
    ↓
[Forks child process]
    ↓
[Child process switches to user UID/GID]
    ↓
[Executes touchid-helper] (running as user)
    ↓
[Creates Unix Domain Socket @ /tmp/touchid-auth.sock]
    ↓
[PAM Module connects to socket]
    ↓
[Helper calls LocalAuthentication API]
    ↓
[User sees Touch ID prompt]
    ↓
[User scans fingerprint]
    ↓
[Helper returns "SUCCESS" or "CANCEL" via socket]
    ↓
[PAM Module returns PAM_SUCCESS or PAM_IGNORE]
    ↓
Sudo either proceeds or falls back to password
```

### Why Two Components?

The PAM module runs as **root**, but Touch ID authentication requires access to the **user's biometric data**. The solution:

- **PAM Module** (root) - Handles sudo authentication requests and IPC
- **Helper** (user) - Runs with user privileges to access biometric templates

This ensures proper access to biometric data while maintaining security.

### Security Features

- ✓ **No privilege escalation** - Helper never runs as root
- ✓ **Limited socket access** - 0600 permissions (user-only)
- ✓ **Process isolation** - Via fork/exec model
- ✓ **No credential passing** - Only success/cancel messages
- ✓ **User interaction required** - Touch ID always requires action
- ✓ **Graceful fallback** - Password auth available on cancel/fail

### Technical Details

**PAM Module** (`src/pam_touchid.m`):
- Forks child process
- Executes helper as user (via setuid/setgid)
- Connects to Unix domain socket
- Handles authentication response
- Returns appropriate PAM codes (PAM_SUCCESS, PAM_IGNORE, PAM_AUTH_ERR)

**User-Space Helper** (`src/touchid-helper.m`):
- Runs with user privileges
- Creates Unix domain socket
- Calls LocalAuthentication API
- Shows Touch ID prompt to user
- Returns authentication result

**IPC Protocol**:
- Transport: Unix domain socket (`/tmp/touchid-auth.sock`)
- Messages: "SUCCESS" or "CANCEL"
- Permissions: 0600 (user-only access)
- Lifecycle: Created per authentication, removed after use

### Files Installed

```
/usr/local/lib/pam/pam_touchid.so      - PAM module
/usr/local/bin/touchid-helper          - User-space helper
/usr/local/bin/touchid-configure       - Manual configuration script
/usr/local/bin/touchid-status          - Status checker
/usr/local/bin/touchid-uninstall       - Uninstaller
/etc/pam.d/sudo_local                  - PAM configuration (modern macOS)
```

### Previous Architecture (Deprecated)

Earlier versions attempted to call LocalAuthentication directly from the PAM module running as root. This resulted in "Biometry not enrolled" errors because the PAM context couldn't access user biometric data. The current two-component architecture solves this by properly handling the context switch.

## Building from Source

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### Build the Components

```bash
# Build PAM module and helper
make build

# This creates:
# - build/pam_touchid.so (34K, shared library)
# - build/touchid-helper (51K, executable)
```

### Available Make Targets

```bash
make build       # Build PAM module and helper
make install     # Install both components (requires sudo)
make uninstall   # Uninstall (requires sudo)
make clean       # Remove build artifacts
make help        # Show available targets
```

### Install Locally

```bash
# Build
make build

# Install
sudo make install

# Configure
sudo ./scripts/configure-sudo.sh

# Verify
sudo touchid-status
```

## Troubleshooting

### Installation Issues

#### "Biometry is not enrolled"
**Status**: FIXED in v1.0.0 (two-component architecture)

If you see this error with an older version, update to v1.0.0:
```bash
sudo touchid-uninstall
# Download and install latest .pkg from Releases
```

#### Touch ID prompt doesn't appear
1. **Verify installation**:
   ```bash
   sudo touchid-status
   ```
   Expected: `✓ Sudo configured for Touch ID`

2. **Verify helper is installed**:
   ```bash
   ls -lh /usr/local/bin/touchid-helper
   # Should show: -rwxr-xr-x
   ```

3. **Check PAM configuration**:
   ```bash
   cat /etc/pam.d/sudo_local
   ```

4. **Review logs**:
   ```bash
   log stream --level debug --predicate 'process == "sudo"'
   ```

#### Socket connection errors
The helper needs time to start. If you see "Failed to connect to helper socket":

1. **Increase system load**: The connection uses retries with delays
2. **Check helper binary permissions**: `ls -lh /usr/local/bin/touchid-helper`
3. **Reinstall**: `sudo make install` or run the .pkg installer again

### Usage Issues

#### Password doesn't work after cancelling Touch ID
This should be automatic in v1.0.0. If it's not:

1. **Wait for Touch ID timeout** (usually 30 seconds)
2. **Or press ESC** to cancel explicitly
3. **Password prompt** should appear

If not working, check logs:
```bash
log stream --level debug --predicate 'process == "sudo"' | grep -i "cancel\|password"
```

#### Authentication fails intermittently
- **Check Touch ID settings**: System Preferences → Touch ID → Verify fingerprints
- **Try re-enrolling a fingerprint**: Add a new fingerprint or re-add existing one
- **Restart**: Sometimes a restart helps with LocalAuthentication caching

#### "Not running as root" errors
Make sure you use `sudo`:
```bash
sudo touchid-status          # ✓ Correct
touchid-status              # ✗ Wrong
```

### Debugging

#### Enable verbose logging
```bash
log stream --level debug --predicate 'process == "sudo" or process == "touchid-helper"'
```

#### Capture full debug session
```bash
# Terminal 1: Start log monitoring
log stream --level debug --predicate 'process == "sudo" or process == "touchid-helper"'

# Terminal 2: Run sudo command
sudo whoami

# Watch logs appear in Terminal 1
```

#### Check system logs for errors
```bash
# Last 50 lines of sudo/touchid activity
log show --predicate 'process == "sudo" or process == "touchid-helper"' --lines 50
```

### Common Questions

**Q: Is this secure?**
A: Yes. The helper never runs as root, socket has 0600 permissions, and Touch ID is handled by macOS Secure Enclave. See ARCHITECTURE.md for details.

**Q: Does this work with Apple Watch?**
A: The current version prioritizes local Touch ID. Apple Watch is not used as an authentication method to ensure the computer is physically present.

**Q: Can I use this over SSH?**
A: No, Touch ID only works locally. SSH sessions will use password authentication, which is correct behavior.

**Q: What if Touch ID fails?**
A: You can cancel and fall back to password. Touch ID failures trigger graceful fallback to password auth.

**Q: Can I make Touch ID required (no password fallback)?**
A: Currently it's optional by design. Edit `/etc/pam.d/sudo_local` to change from `optional` to `required` (not recommended).

**Q: Does it work on older Macs?**
A: Requires a Mac with Touch ID (2013 MacBook Pro or later with Touch Bar, or any M1+).

**Q: Will this slow down sudo?**
A: Slightly (~200-400ms for Touch ID), but much faster than typing a password.

## Security Considerations

- The PAM module runs as root (required for sudo)
- Touch ID authentication is handled by macOS Secure Enclave
- Password remains a fallback option (optional mode)
- The module logs authentication attempts to system log
- No passwords are stored or transmitted by this module

## File Structure

```
touchid-for-sudo/
├── README.md                          # This file
├── ARCHITECTURE.md                    # Technical architecture details
├── TESTING.md                         # Testing and troubleshooting guide
├── Makefile                           # Build configuration
├── src/
│   ├── pam_touchid.m                  # PAM module (IPC client)
│   └── touchid-helper.m               # User-space helper (IPC server)
├── scripts/
│   ├── configure-sudo.sh              # Configure sudo for Touch ID
│   ├── uninstall.sh                   # Uninstall module
│   └── status.sh                      # Check installation status
├── build/
│   └── package.sh                     # Create macOS .pkg installer
└── resources/
    └── Info.plist                     # Bundle information
```

## Documentation

- **README.md** (this file) - Overview and quick start
- **ARCHITECTURE.md** - Detailed technical architecture and IPC protocol
- **TESTING.md** - Installation, testing, troubleshooting, and performance guide
- **Source Code Comments** - Comprehensive inline documentation

## Version History

### v1.0.0 (Current - Production Release)

**Major Release: Two-Component Architecture with IPC**

#### New Features
- ✨ User-space helper for proper biometric authentication
- ✨ Secure IPC via Unix domain socket (0600 permissions)
- ✨ Helper runs as user (never elevated to root)
- ✨ Production-ready one-click .pkg installer
- ✨ Comprehensive architecture and testing documentation

#### Fixes & Improvements
- 🐛 Fixed "Biometry not enrolled" errors in PAM context
- 🐛 Proper user context access to biometric templates
- 🐛 Graceful password fallback on authentication failure
- 🐛 Connection retry logic for IPC reliability
- 🐛 Improved error handling and logging

#### Technical Improvements
- 🔧 Complete rewrite of PAM module for IPC
- 🔧 New touchid-helper executable for user-space auth
- 🔧 Dual-component build system
- 🔧 Enhanced socket communication protocol
- 🔧 Comprehensive system logging

#### What Users Get
- 📦 Ready-to-use .pkg installer (no compilation needed)
- 📚 ARCHITECTURE.md - Complete technical details
- 📚 TESTING.md - Installation and troubleshooting guide
- 🔒 Security-first design with no privilege escalation
- ✅ Production-tested and ready for deployment

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details

## Author

Maksim Vialykh

## Support

Having issues? Please file an issue on GitHub or check the Troubleshooting section above.

For updates and news: Follow the project on GitHub

---

**Made with ❤️ for the macOS community**

> If this tool helps you save time and makes your workflow smoother, please consider supporting the project with a donation:
> [![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=flat-square&logo=paypal)](https://paypal.me/vialyx)