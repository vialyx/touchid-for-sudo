# Debugging Touch ID Authentication Issue

## The Problem

You have:
- ✓ PAM module installed
- ✓ Sudo configured for Touch ID
- ✗ But `sudo whoami` asks for password instead of Touch ID

## Solution: Enhanced Logging

I've added comprehensive logging to the PAM module so we can see exactly what's happening when you try to authenticate.

## View Live Logs

### Real-time Log Monitoring
```bash
# Monitor all pam_touchid logs in real-time
log stream --predicate 'process contains "sudo"' --level debug | grep pam_touchid

# Or in another terminal, run sudo command:
sudo whoami
```

### View System Logs
```bash
# Show recent pam_touchid logs
log show --predicate 'process contains "pam"' --last 1h | grep pam_touchid

# Or search for specific error patterns
log show --predicate 'message contains "pam_touchid"' --last 1h
```

### Test and Debug
```bash
# 1. First, reinstall the updated package
open /Users/maksimvialykh/github/touchid-for-sudo/TouchID-for-Sudo-1.0.0.pkg

# 2. In one terminal, watch logs:
log stream --predicate 'process contains "sudo"' --level debug

# 3. In another terminal, test:
sudo whoami

# 4. Look at output - it will show exactly what's happening
```

## What the Logs Will Show

### Success Case
```
pam_touchid: Authentication module called
pam_touchid: Authenticating user: your_username
pam_touchid: LAContext created successfully
pam_touchid: Touch ID is available, proceeding with authentication
pam_touchid: Starting authentication attempt 1 of 3
pam_touchid: Calling evaluatePolicy with BiometricsOnly policy
pam_touchid: Waiting for Touch ID response...
pam_touchid: Touch ID response received (success=1)
pam_touchid: ✓ Touch ID authentication SUCCESSFUL for user your_username
```

### Failure Cases

**If Touch ID not available:**
```
pam_touchid: Touch ID not available or disabled (policy check failed)
pam_touchid: Error from canEvaluatePolicy: [error code]
```

**If user cancels:**
```
pam_touchid: User cancelled Touch ID
```

**If Touch ID not configured:**
```
pam_touchid: Passcode not set on device
```

**If module not being called:**
```
# No pam_touchid logs appear at all
# This means sudo isn't loading the module
```

## Troubleshooting Steps

### Step 1: Verify Module is Loaded
```bash
# Check if module file exists and has correct permissions
ls -lh /usr/local/lib/pam/pam_touchid.so

# Should show: -rw-r--r-- (readable by sudo)
```

### Step 2: Verify sudo_local Configuration
```bash
# Check if sudo_local has correct configuration
cat /etc/pam.d/sudo_local

# Should show:
# auth       sufficient     /usr/local/lib/pam/pam_touchid.so
```

### Step 3: Test with Logging
```bash
# Watch logs in real-time
log stream --predicate 'message contains "pam_touchid"' --level debug &

# Then try sudo
sudo whoami

# Check output - if no logs appear, module isn't being called
# If logs appear with errors, we know what's failing
```

### Step 4: Check sudo Configuration
```bash
# Verify sudo includes sudo_local
cat /etc/pam.d/sudo

# Should contain: auth include sudo_local
```

### Step 5: Verify Touch ID Works System-Wide
```bash
# Check if Touch ID works in other contexts
# (e.g., unlocking macOS, using app purchases, etc.)
```

## Common Issues and Solutions

### Issue: Module Not Being Called
**Symptom:** No pam_touchid logs appear when running sudo

**Causes:**
1. Module file doesn't exist or wrong permissions
2. sudo_local not in correct location
3. sudo_local not in correct format

**Fix:**
```bash
# Reinstall
open /Users/maksimvialykh/github/touchid-for-sudo/TouchID-for-Sudo-1.0.0.pkg

# Or manually configure
sudo touchid-configure
```

### Issue: Touch ID Not Available
**Symptom:** Logs show "Touch ID not available or disabled"

**Causes:**
1. Touch ID disabled in System Preferences
2. Device doesn't have Touch ID (wrong Mac model)
3. Touch ID hardware issue

**Fix:**
1. Check System Preferences → Security & Privacy → Touch ID
2. Try using Touch ID for other system functions
3. Restart Mac if needed

### Issue: User Cancels Touch ID
**Symptom:** Logs show "User cancelled Touch ID"

**This is normal** - user can retry or enter password

### Issue: Module Crashes
**Symptom:** System appears to hang or crash during sudo

**Fix:**
- Check logs for specific error
- Reinstall package
- Contact support with log output

## Getting Debug Information for Support

If nothing works, gather this info:

```bash
# 1. Get full logs from last 30 minutes
log show --predicate 'message contains "pam"' --last 30m > ~/pam_logs.txt

# 2. Check module file
ls -lh /usr/local/lib/pam/pam_touchid.so

# 3. Check sudo configuration
cat /etc/pam.d/sudo
cat /etc/pam.d/sudo_local

# 4. Check Touch ID availability
system_profiler SPPlatformReporterDataType | grep Touch

# 5. Try test command with verbose output
sudo -v
sudo whoami

# Share all this information for debugging
```

## Installation Steps

1. **Backup current state:**
   ```bash
   sudo cp /etc/pam.d/sudo_local /etc/pam.d/sudo_local.backup.before-debug
   ```

2. **Install new package:**
   ```bash
   open /Users/maksimvialykh/github/touchid-for-sudo/TouchID-for-Sudo-1.0.0.pkg
   ```

3. **Start log monitoring:**
   ```bash
   log stream --predicate 'message contains "pam_touchid"' --level debug
   ```

4. **In another terminal, test:**
   ```bash
   sudo whoami
   ```

5. **Check the logs** - they will tell us exactly what's happening

## Next Steps

1. Reinstall the package with enhanced logging
2. Monitor logs while testing `sudo whoami`
3. Share the log output so we can diagnose the exact issue
4. Once we know the problem, we can fix it

The logs will provide the information we need to solve this!
