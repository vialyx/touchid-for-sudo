# Testing Guide - Phase 7 Fixes

## Quick Start Test

### 1. Fresh Installation Test
```bash
# Create backup of current sudo config (important!)
sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.backup.current

# Install the package
open TouchID-for-Sudo-1.0.0.pkg

# Follow installer prompts
# Installation should complete with configuration

# Check if Touch ID was auto-configured
grep "pam_touchid.so" /etc/pam.d/sudo
# Should output: auth       sufficient     /usr/local/lib/pam/pam_touchid.so
```

### 2. PAM Module Crash Test
```bash
# This should NOT crash with "unrecognized selector" error
sudo whoami

# You should see:
# 1. Touch ID prompt appears
# 2. Authenticate with Touch ID
# 3. "username" is returned
# 4. No crash/exception
```

### 3. Monitor Installation
```bash
# In one terminal, watch the installation logs:
log stream --predicate 'process == "touchid-postinstall"' --level debug

# In another terminal, install the package:
open TouchID-for-Sudo-1.0.0.pkg

# You should see debug output from postinstall script
```

### 4. Verify Configuration
```bash
# Check if PAM configuration was applied
cat /etc/pam.d/sudo

# Should show pam_touchid.so BEFORE pam_unix.so:
# auth       sufficient     /usr/local/lib/pam/pam_touchid.so
# auth       required       pam_unix.so
# ...
```

### 5. Status Check
```bash
touchid-status

# Should output:
# ✓ PAM module installed
# ✓ Sudo configured for Touch ID
# ✓ Touch ID available
```

## Troubleshooting

### If sudo still crashes:
```bash
# Check system logs for errors
log show --process pam_touchid --level debug

# Verify PAM module is installed
ls -la /usr/local/lib/pam/pam_touchid.so

# Check if it's being loaded
syslog -k process eq pam_touchid
```

### If postinstall didn't configure sudo:
```bash
# Manually configure
sudo ./scripts/configure-sudo.sh

# Or use the helper command
sudo touchid-configure
```

### If you need to restore:
```bash
# Restore from backup
sudo cp /etc/pam.d/sudo.backup.current /etc/pam.d/sudo

# Or uninstall
sudo touchid-uninstall
```

## Expected Behavior After Fixes

✅ **Installation Process**
- Opens installer UI
- Shows "Installing..." progress
- Postinstall script automatically configures sudo
- Installation completes

✅ **First sudo Command**
- `sudo whoami` shows Touch ID prompt
- No crash or exception
- Touch ID authentication works
- Returns username

✅ **Seamless Usage**
- All `sudo` commands trigger Touch ID
- No need to enter password
- Can still use password as fallback (if set)

## What Was Fixed

### 1. PAM Module API Issue
- **Before**: `sudo` crashed with "unrecognized selector" error
- **After**: `sudo` commands properly show Touch ID prompt and work correctly

### 2. Postinstall Script
- **Before**: Sudo configuration not applied automatically
- **After**: Postinstall script properly configures sudo during installation

## Files Tested
- ✓ src/pam_touchid.m (compiles without errors)
- ✓ build/package.sh (creates package successfully)
- ✓ TouchID-for-Sudo-1.0.0.pkg (ready to install)

## Command Reference

```bash
# Status
touchid-status

# Manual configure
sudo touchid-configure

# Manual uninstall
sudo touchid-uninstall

# View logs
log stream --predicate 'process == "touchid-postinstall"'

# Check sudo config
sudo cat /etc/pam.d/sudo | grep pam_touchid
```

## Success Criteria

Installation is successful when:
1. ✓ Package installs without errors
2. ✓ Postinstall script outputs appear in logs
3. ✓ `grep pam_touchid /etc/pam.d/sudo` shows the module
4. ✓ `sudo whoami` shows Touch ID prompt (no crash)
5. ✓ Touch ID authentication succeeds
6. ✓ `touchid-status` shows all green ✓ marks
