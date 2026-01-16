# Touch ID for Sudo - Architecture

## Overview

Touch ID for Sudo implements a **two-component architecture** to properly handle biometric authentication in the PAM (Pluggable Authentication Modules) context.

## Problem Statement

The PAM module runs as **root**, but Touch ID authentication requires access to the user's biometric data, which is stored in the user's security context. LocalAuthentication cannot access this data when running as root, resulting in "Biometry is not enrolled" errors even when the user has Touch ID configured.

## Solution

We use **Inter-Process Communication (IPC)** between:

1. **PAM Module** (running as root)
2. **User-Space Helper** (running as the authenticated user)

This allows the helper to access the user's biometric data while the PAM module manages the authentication flow.

## Architecture Diagram

```
User runs: sudo whoami
    ↓
[sudo process]
    ↓
[PAM Stack - authentication]
    ↓
[PAM Module - pam_touchid.so] (running as root)
    ↓
    Forks child process
    ↓
[Child Process] switches to user UID/GID
    ↓
[touchid-helper] (running as user)
    Creates Unix Domain Socket
    ↓
[PAM Module] connects to socket
    ↓
[touchid-helper] calls LocalAuthentication
    ↓
User sees Touch ID prompt and authenticates
    ↓
[touchid-helper] sends response ("SUCCESS" or "CANCEL")
    ↓
[PAM Module] receives response, returns PAM_SUCCESS or PAM_IGNORE
    ↓
[PAM Stack] allows or rejects authentication
    ↓
[sudo] either proceeds or falls back to password
```

## Components

### 1. PAM Module (`src/pam_touchid.m`)

**Responsibilities:**
- Acts as the authentication handler for `sudo`
- Runs with root privileges
- Forks a child process to run the helper as the authenticated user
- Connects to the helper via Unix domain socket
- Receives and interprets the authentication result
- Returns appropriate PAM return codes

**Key Functions:**
- `authenticate_via_helper()` - Main IPC handler
  - Gets user info
  - Forks and executes helper
  - Connects to socket
  - Reads response
  - Returns PAM_SUCCESS or PAM_IGNORE

**PAM Return Codes:**
- `PAM_SUCCESS` - Authentication successful
- `PAM_IGNORE` - Fall back to next auth module (allows password)
- `PAM_AUTH_ERR` - Fatal error

### 2. User-Space Helper (`src/touchid-helper.m`)

**Responsibilities:**
- Runs with user privileges (UID/GID of authenticated user)
- Creates a Unix domain socket for IPC
- Performs LocalAuthentication API calls
- Sends result back to PAM module

**Key Features:**
- Accepts single connection from PAM module
- Calls `LAContext.evaluatePolicy()` with `LAPolicyDeviceOwnerAuthentication`
- User sees Touch ID prompt on their Mac (not Apple Watch)
- Returns "SUCCESS" or "CANCEL" response

**Communication Protocol:**
- Simple text-based responses over Unix socket
- "SUCCESS" - User authenticated with Touch ID
- "CANCEL" - User cancelled, Touch ID unavailable, or error occurred

### 3. Build System (`Makefile`)

**Targets:**
- `make build` - Compiles both PAM module and helper
- `make install` - Installs to `/usr/local/lib/pam/` and `/usr/local/bin/`
- `make clean` - Removes build artifacts

### 4. Installer (`build/package.sh`)

**Package Creation:**
- Bundles both PAM module and helper
- Creates `/etc/pam.d/sudo_local` on installation
- Configures sudo to use Touch ID automatically
- Size: ~16KB

## Security Considerations

1. **Privilege Escalation:**
   - Helper runs with user privileges, never elevated
   - PAM module enforces root check before starting
   - No privilege is granted via socket communication

2. **Socket Permissions:**
   - Created at `/tmp/touchid-auth.sock`
   - Set to 0600 (user-only read/write)
   - Removed after use
   - Not persistent between sessions

3. **User Context:**
   - Helper correctly switches UID/GID before exec
   - Child process isolation via fork
   - No credential passing over socket

4. **Authentication Flow:**
   - Touch ID prompt requires user interaction
   - No automatic approval
   - User can cancel to fall back to password

## IPC Protocol

### Connection Flow

```
1. PAM Module (root) forks child
2. Child process switches to user UID/GID
3. Child executes touchid-helper
   - Creates AF_UNIX socket
   - Binds to /tmp/touchid-auth.sock
   - Sets permissions to 0600
   - Listens for connection

4. PAM Module (parent, root) connects to socket
   - Connects to /tmp/touchid-auth.sock
   - Waits for response

5. Helper accepts connection
   - Calls LocalAuthentication API
   - Waits for user interaction
   - Reads success/cancel result

6. Helper sends response
   - Writes "SUCCESS" or "CANCEL"
   - Closes socket
   - Exits

7. PAM Module reads response
   - Interprets result
   - Returns appropriate PAM code
```

## Environment Setup

**Required Files After Installation:**

```
/usr/local/lib/pam/pam_touchid.so      - PAM module (shared library)
/usr/local/bin/touchid-helper          - User-space helper (executable)
/usr/local/bin/touchid-configure       - Manual configuration script
/usr/local/bin/touchid-status          - Status check utility
/usr/local/bin/touchid-uninstall       - Removal script
/etc/pam.d/sudo_local                  - PAM configuration (created on install)
```

## Error Handling

The helper gracefully handles various error scenarios:

- **Biometry not enrolled:** Falls back to password (returns "CANCEL")
- **User cancels:** Falls back to password (returns "CANCEL")
- **Touch ID unavailable:** Falls back to password (returns "CANCEL")
- **Passcode not set:** Falls back to password (returns "CANCEL")
- **IPC connection failure:** PAM returns PAM_AUTH_ERR
- **Helper execution failure:** PAM returns PAM_AUTH_ERR

## Performance

- **Helper startup:** ~100ms
- **Touch ID prompt appearance:** ~200ms
- **User interaction time:** Depends on user
- **Total auth time:** ~400ms + user interaction

## Compatibility

- **macOS 10.15+** - Required for modern LocalAuthentication
- **ARM64 (Apple Silicon):** Fully supported
- **Intel x86_64:** Fully supported (if compiled)
- **Apple Watch:** Skipped in favor of local biometrics

## Future Enhancements

- Caching authentication result for short time periods
- Support for Face ID
- Timeout configuration
- Biometric retry limits
- Helper auto-updates via package manager
