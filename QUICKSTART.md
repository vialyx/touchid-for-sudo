# Quick Start Guide

## Installation in 3 Steps

### Step 1: Clone the Repository
```bash
git clone https://github.com/maksimvialykh/touchid-for-sudo.git
cd touchid-for-sudo
```

### Step 2: Run the Installer
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

The installer will:
- Check for Xcode Command Line Tools
- Build the Touch ID PAM module
- Install it to `/usr/local/lib/pam/pam_touchid.so`
- Configure sudo to use Touch ID
- Make all helper scripts executable

### Step 3: Test It
Open a new Terminal and run:
```bash
sudo whoami
```

You should see a Touch ID prompt! Authenticate with your fingerprint.

## Usage

After installation, every `sudo` command will offer Touch ID authentication:

```bash
sudo whoami          # Touch ID prompt appears
sudo ls /root        # Touch ID prompt appears
sudo -v              # Validate sudo session with Touch ID
```

## Management

### Check Installation Status
```bash
./scripts/status.sh
```

### Verify Everything Works
```bash
./scripts/verify.sh
```

### Uninstall (if needed)
```bash
sudo ./scripts/uninstall.sh
```

This will safely restore your original sudo configuration from backup.

## Troubleshooting

### Touch ID Not Appearing?

1. **Restart Terminal**: Close and reopen Terminal.app
2. **Check Configuration**:
   ```bash
   ./scripts/status.sh
   ```
3. **View System Logs**:
   ```bash
   log stream --predicate 'eventMessage contains "pam_touchid"' --level debug
   ```

### Build Fails?

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### Can't Run Scripts?

Make them executable:
```bash
chmod +x scripts/*.sh
```

## Important Notes

- Installation requires `sudo` privileges
- A backup of your original `/etc/pam.d/sudo` is automatically saved
- Touch ID is optional by default - password fallback is available
- The module is configured to log all authentication attempts

## Next Steps

- Read the [full README](README.md) for detailed documentation
- Check [CONTRIBUTING.md](CONTRIBUTING.md) if you want to contribute
- Review [CHANGELOG.md](CHANGELOG.md) for version history

## Support

Having issues? 
- Check [TROUBLESHOOTING](README.md#troubleshooting) in the README
- Open an issue on GitHub
- Review system logs for errors

---

**Need help?** Check the Troubleshooting section in [README.md](README.md#troubleshooting)
