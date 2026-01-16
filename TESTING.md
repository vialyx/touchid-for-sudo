# Installation & Testing Guide

## Installation

### From Package (Recommended)

```bash
# Download the latest .pkg from releases
open TouchID-for-Sudo-1.0.0.pkg

# Follow the installer
# Sudo will be automatically configured
```

### From Source

```bash
# Clone repository
git clone https://github.com/vialyx/touchid-for-sudo.git
cd touchid-for-sudo

# Build
make build

# Install
sudo make install

# Configure
sudo ./scripts/configure-sudo.sh
```

## Verification

### Check Installation Status

```bash
touchid-status
```

Expected output:
```
✓ Sudo configured for Touch ID
```

### Check Helper Installed

```bash
which touchid-helper
ls -lh /usr/local/bin/touchid-helper
```

Expected:
```
/usr/local/bin/touchid-helper
-rwxr-xr-x  1 root  wheel  51K Jan 16 12:43 /usr/local/bin/touchid-helper
```

## Testing

### Test 1: Touch ID Authentication

```bash
sudo whoami
```

**Expected Behavior:**
1. Touch ID prompt appears on Mac
2. Use fingerprint to authenticate
3. Command executes successfully

**Logs:**
```bash
log stream --level debug --predicate 'process == "sudo"'
```

Look for:
```
pam_touchid: Authentication module called
pam_touchid: Authenticating user: <username>
pam_touchid: Parent process waiting for helper to be ready
pam_touchid: Connected to helper, waiting for authentication result
pam_touchid: Helper returned response: SUCCESS
pam_touchid: ✓ Touch ID authentication SUCCESSFUL
```

### Test 2: Password Fallback

```bash
sudo whoami
```

**Expected Behavior:**
1. Touch ID prompt appears
2. Wait for timeout OR press Cancel/ESC
3. Password prompt appears
4. Type password
5. Command executes

**Logs:**
```
pam_touchid: User cancelled Touch ID - falling back to password
```

### Test 3: Retry on Failure

```bash
sudo whoami
```

**Expected Behavior:**
1. Touch ID prompt appears
2. Failed attempt (wrong finger, etc.)
3. Prompt appears again for retry
4. After 3 failed attempts → password fallback

### Test 4: Multiple Commands

```bash
sudo whoami
sudo ls /root
sudo cat /etc/shadow
```

Each should work with Touch ID.

## Troubleshooting

### Issue: "Biometry is not enrolled"

**Cause:** Old cached package
**Solution:**
```bash
sudo touchid-uninstall
open TouchID-for-Sudo-1.0.0.pkg
```

### Issue: Touch ID prompt doesn't appear

**Cause:** Helper not installed or not executable
**Solution:**
```bash
ls -lh /usr/local/bin/touchid-helper
# Should be: -rwxr-xr-x 1 root wheel

# Reinstall if needed:
sudo make install
```

### Issue: Password doesn't work after cancelling

**Cause:** PAM module returned error instead of allowing fallback
**Solution:**
```bash
# Check logs:
log stream --predicate 'process == "sudo"' --level debug

# Reinstall with latest version
sudo touchid-uninstall
make clean build
sudo make install
```

### Issue: Helper crashes

**Check helper logs:**
```bash
log stream --predicate 'process == "touchid-helper"' --level debug
```

## Real-World Usage

### Terminal Session

```bash
$ sudo whoami
[Touch ID prompt appears]
[Scan fingerprint]
root

$ sudo ls /var/log
[Touch ID prompt appears]
[Scan fingerprint]
system.log  ...

$ sudo -i
[Touch ID prompt appears]
[Scan fingerprint]
root#
```

### Remote Sessions (SSH)

Touch ID **does not work** over SSH (expected behavior):
```bash
$ ssh user@remote.com
user@remote.com $ sudo whoami
Password:  [Falls back to password]
root
```

This is correct - SSH cannot access local biometric hardware.

## Uninstallation

### Using Script

```bash
sudo touchid-uninstall
```

### Manual

```bash
sudo rm /usr/local/lib/pam/pam_touchid.so
sudo rm /usr/local/bin/touchid-helper
sudo rm /etc/pam.d/sudo_local
```

## Performance Notes

- **First authentication:** ~500ms + user interaction
- **Subsequent attempts:** ~300ms + user interaction
- **Helper startup:** ~100-150ms
- **IPC communication:** <50ms

## Advanced Testing

### Enable Debug Logging

```bash
# Clear logs first
log erase --all

# Run command
sudo whoami

# View detailed logs
log show --predicate 'process == "sudo"' --level debug
log show --predicate 'process == "touchid-helper"' --level debug
```

### Stress Testing

```bash
# Run multiple sudo commands rapidly
for i in {1..10}; do
    sudo whoami
    sleep 1
done
```

### Test with Apple Watch

If you wear an Apple Watch:
```bash
sudo whoami
# Should still show Touch ID prompt on Mac
# Not offer Apple Watch authentication
```

### Test Error Scenarios

```bash
# Kill helper mid-auth to test error handling
# (Advanced - for developers)
sudo whoami &
sleep 0.5
pkill -f touchid-helper
# PAM should fall back to password
```

## Monitoring

### Watch Authentication Attempts

```bash
log stream --level debug --predicate 'process == "sudo"' 
```

### Count Successful Authentications

```bash
log show --level debug --predicate 'process == "sudo"' | grep "SUCCESSFUL" | wc -l
```

### Monitor Helper Process

```bash
# While running sudo whoami in another terminal:
ps aux | grep touchid-helper
```

Expected to see touchid-helper process running briefly.

## Support

If you encounter issues:

1. Collect logs: `log show --predicate 'process == "sudo" or process == "touchid-helper"' --level debug`
2. Check installed files: `ls -lh /usr/local/{lib/pam/,bin/touchid-*}`
3. Verify PAM config: `cat /etc/pam.d/sudo_local`
4. Report on GitHub with logs attached
