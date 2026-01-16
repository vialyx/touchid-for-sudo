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
