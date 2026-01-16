# Touch ID for Sudo

> **Support This Project**
> [![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?style=flat-square&logo=paypal)](https://paypal.me/vialyx) - If this tool helps you, please consider making a donation!

Enable biometric Touch ID authentication for `sudo` on macOS. This project provides a PAM (Pluggable Authentication Module) that allows you to use your Mac's Touch ID instead of typing your password for sudo commands.

## Features

- ✅ **Biometric Authentication**: Use Touch ID for sudo instead of typing passwords
- ✅ **macOS Native**: Uses Apple's LocalAuthentication framework
- ✅ **Secure**: Works with macOS security architecture
- ✅ **Easy Installation**: Simple installation script with one command
- ✅ **Easy Removal**: Fully reversible with backup restoration
- ✅ **Apple Silicon & Intel**: Works on both ARM64 and x86_64 Macs
- ✅ **Retry Logic**: Automatic retry support for failed attempts
- ✅ **Logging**: Comprehensive system logging for debugging

## Requirements

- macOS 10.15 (Catalina) or later
- Mac with Touch ID support (MacBook Pro with Touch Bar, MacBook Air M1+, etc.)
- Xcode Command Line Tools
- Administrator access (sudo)

## Installation

### Quick Start

```bash
git clone https://github.com/maksimvialykh/touchid-for-sudo.git
cd touchid-for-sudo
chmod +x scripts/install.sh
./scripts/install.sh
```

The installation script will:
1. ✓ Check prerequisites
2. ✓ Build the PAM module
3. ✓ Install the module
4. ✓ Configure sudo to use Touch ID
5. ✓ Display status

### Manual Installation

If you prefer to install step by step:

```bash
# Build the module
make build

# Install the module (requires sudo)
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

To remove Touch ID for Sudo:

```bash
sudo ./scripts/uninstall.sh
```

This will:
1. ✓ Remove the PAM module
2. ✓ Restore the original sudo configuration from backup
3. ✓ Optionally remove backup files

## How It Works

The project consists of:

- **`src/pam_touchid.c`**: The PAM module that handles Touch ID authentication using the LocalAuthentication framework
- **`Makefile`**: Builds the PAM module using clang with proper frameworks
- **`scripts/install.sh`**: Complete installation automation
- **`scripts/configure-sudo.sh`**: Configures sudo to use the PAM module
- **`scripts/uninstall.sh`**: Safely removes the module and restores backups
- **`scripts/status.sh`**: Shows current installation status
- **`build/package.sh`**: Creates a macOS .pkg installer

### Architecture

```
User runs: sudo command
          ↓
     PAM Authorization
          ↓
    pam_touchid.so (custom module)
          ↓
   LocalAuthentication Framework
          ↓
   Touch ID Sensor / Secure Enclave
          ↓
  Authentication Success/Failure
          ↓
  Grant/Deny sudo privileges
```

## Building from Source

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### Build

```bash
make build
```

This compiles the PAM module using clang with:
- LocalAuthentication framework
- Foundation framework
- PAM library

### Available Make Targets

```bash
make build       # Build the PAM module
make install     # Install module (requires sudo)
make uninstall   # Uninstall module (requires sudo)
make clean       # Remove build artifacts
make help        # Show available targets
make info        # Show system information
```

## Troubleshooting

### Touch ID not appearing when using sudo

1. **Check installation**:
   ```bash
   ./scripts/status.sh
   ```

2. **Verify PAM module is installed**:
   ```bash
   ls -l /usr/local/lib/pam/pam_touchid.so
   ```

3. **Check sudo configuration**:
   ```bash
   grep pam_touchid /etc/pam.d/sudo
   ```

4. **Restart Terminal**: Close and reopen Terminal.app

### Authentication fails

- Ensure Touch ID is enabled on your Mac (System Preferences → Touch ID)
- Verify your fingerprints are registered
- Check system logs: `log stream --predicate 'eventMessage contains "pam_touchid"' --level debug`

### "Permission denied" when running scripts

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### Build errors

Ensure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

## Security Considerations

- The PAM module runs as root (required for sudo)
- Touch ID authentication is handled by macOS Secure Enclave
- Password remains a fallback option (optional mode)
- The module logs authentication attempts to system log
- No passwords are stored or transmitted by this module

## File Structure

```
touchid-for-sudo/
├── README.md                     # This file
├── Makefile                      # Build configuration
├── src/
│   └── pam_touchid.c            # PAM module source code
├── scripts/
│   ├── install.sh               # Automated installation
│   ├── configure-sudo.sh        # Configure sudo
│   ├── uninstall.sh             # Uninstall module
│   └── status.sh                # Check installation status
├── build/
│   └── package.sh               # Create macOS .pkg
└── resources/
    └── Info.plist               # Bundle information
```

## Version History

### v1.0.0 (Current)
- Initial release
- Touch ID authentication for sudo
- Automatic installation/uninstallation
- Comprehensive documentation

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