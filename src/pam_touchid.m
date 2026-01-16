/*
 * PAM module for Touch ID authentication on macOS
 * Allows using Touch ID instead of password for sudo authentication
 *
 * Compile: gcc -fPIC -shared -o pam_touchid.so pam_touchid.c -lpam
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>
#include <syslog.h>
#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <LocalAuthentication/LocalAuthentication.h>
#include <Foundation/Foundation.h>

#define PAM_TOUCHID_MAX_RETRIES 3

/* Use syslog instead of pam_syslog */
#define pam_syslog(h, p, f, ...) syslog(p, f, ##__VA_ARGS__)

/*
 * pam_sm_authenticate - Perform authentication via Touch ID
 * 
 * This module requires local biometric authentication (Touch ID/Face ID)
 * on the device itself, not Apple Watch. This ensures that users can
 * authenticate directly on their computer with their fingerprint or face.
 */
PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                                    int argc, const char **argv) {
    const char *user;
    int retval;
    int i;
    BOOL touchIdSupported = NO;
    NSError *error = nil;
    
    /* Log module invocation */
    pam_syslog(pamh, LOG_NOTICE, "pam_touchid: Authentication module called");
    
    /* Get the user name */
    retval = pam_get_user(pamh, &user, NULL);
    if (retval != PAM_SUCCESS) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to get username (retval=%d)", retval);
        return retval;
    }
    
    if (user == NULL) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Username is NULL");
        return PAM_USER_UNKNOWN;
    }
    
    pam_syslog(pamh, LOG_NOTICE, "pam_touchid: Authenticating user: %s", user);
    
    /* Check if running as root (sudo context) */
    if (geteuid() != 0 && getuid() != 0) {
        pam_syslog(pamh, LOG_WARNING, "pam_touchid: Not running as root (euid=%d, uid=%d)", geteuid(), getuid());
        return PAM_AUTH_ERR;
    }
    
    /* Initialize Autorelease Pool for Objective-C memory management */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Initialized Objective-C autorelease pool");
    
    /* Check if Touch ID is available */
    LAContext *context = [[LAContext alloc] init];
    if (context == nil) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to create LAContext");
        [pool drain];
        return PAM_AUTH_ERR;
    }
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: LAContext created successfully");
    
    /* Check device capability */
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Checking if device can evaluate authentication policies");
    
    /* Use LAPolicyDeviceOwnerAuthenticationWithBiometrics to force local Touch ID/Face ID only (no Apple Watch) */
    LAPolicy policyToUse = LAPolicyDeviceOwnerAuthenticationWithBiometrics;
    BOOL canEvaluate = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    if (!canEvaluate) {
        pam_syslog(pamh, LOG_WARNING, "pam_touchid: Cannot evaluate standard policy");
        if (error) {
            LAError errorCode = [error code];
            NSString *errorDesc = [error localizedDescription];
            pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Error code: %ld, Description: %s", 
                      (long)errorCode, [errorDesc UTF8String]);
        }
        [context release];
        [pool drain];
        return PAM_AUTH_ERR;
    }
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Device can evaluate authentication, proceeding");
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Touch ID is available, proceeding with authentication");
    touchIdSupported = YES;
    
    /* Attempt Touch ID authentication with retries */
    for (i = 0; i < PAM_TOUCHID_MAX_RETRIES; i++) {
        error = nil;
        
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Starting authentication attempt %d of %d", i + 1, PAM_TOUCHID_MAX_RETRIES);
        
        /* Use synchronous evaluation with proper method signature */
        __block BOOL authSuccess = NO;
        __block LAError authError = 0;
        
        /* Create a dispatch semaphore to wait for async completion */
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        /* Use LAPolicyDeviceOwnerAuthentication - allows Touch ID, Face ID, Apple Watch, or passcode */
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Calling evaluatePolicy");
        
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:@"Authenticate with Touch ID for sudo"
                         reply:^(BOOL success, NSError *error) {
            pam_syslog(pamh, LOG_DEBUG, "pam_touchid: evaluatePolicy callback: success=%d, error=%@", success, error);
            authSuccess = success;
            if (error) {
                authError = [error code];
                pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Authentication error code: %ld", (long)authError);
            }
            dispatch_semaphore_signal(sema);
        }];
        
        /* Wait for authentication to complete */
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Waiting for Touch ID response...");
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Touch ID response received (success=%d)", authSuccess);
        
        if (authSuccess) {
            /* Authentication successful */
            pam_syslog(pamh, LOG_NOTICE, "pam_touchid: ✓ Touch ID authentication SUCCESSFUL for user %s", user);
            [context release];
            [pool drain];
            return PAM_SUCCESS;
        } else {
            /* Authentication failed */
            pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Authentication attempt %d failed (authError=%ld)", i + 1, (long)authError);
            
            if (authError != 0) {
                LAError errorCode = authError;
                
                if (errorCode == LAErrorUserCancel) {
                    pam_syslog(pamh, LOG_NOTICE, "pam_touchid: User cancelled Touch ID - falling back to password");
                    [context release];
                    [pool drain];
                    return PAM_IGNORE;
                } else if (errorCode == LAErrorTouchIDNotAvailable) {
                    pam_syslog(pamh, LOG_WARNING, "pam_touchid: Touch ID not available - falling back to password");
                    [context release];
                    [pool drain];
                    return PAM_IGNORE;
                } else if (errorCode == LAErrorPasscodeNotSet) {
                    pam_syslog(pamh, LOG_WARNING, "pam_touchid: Passcode not set - falling back to password");
                    [context release];
                    [pool drain];
                    return PAM_IGNORE;
                }
            }
            
            if (i < PAM_TOUCHID_MAX_RETRIES - 1) {
                pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Authentication attempt %d failed, retrying...", i + 1);
            }
        }
    }
    
    pam_syslog(pamh, LOG_WARNING, "pam_touchid: Maximum authentication attempts exceeded - falling back to password");
    [context release];
    [pool drain];
    return PAM_IGNORE;
}

/*
 * pam_sm_setcred - Set credentials (not used for Touch ID)
 */
PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags,
                               int argc, const char **argv) {
    return PAM_SUCCESS;
}

/*
 * pam_sm_acct_mgmt - Check account validity (not used)
 */
PAM_EXTERN int pam_sm_acct_mgmt(pam_handle_t *pamh, int flags,
                                 int argc, const char **argv) {
    return PAM_SUCCESS;
}

/*
 * pam_sm_open_session - Open session (not used)
 */
PAM_EXTERN int pam_sm_open_session(pam_handle_t *pamh, int flags,
                                    int argc, const char **argv) {
    return PAM_SUCCESS;
}

/*
 * pam_sm_close_session - Close session (not used)
 */
PAM_EXTERN int pam_sm_close_session(pam_handle_t *pamh, int flags,
                                     int argc, const char **argv) {
    return PAM_SUCCESS;
}

/*
 * pam_sm_chauthtok - Change authentication token (not used)
 */
PAM_EXTERN int pam_sm_chauthtok(pam_handle_t *pamh, int flags,
                                 int argc, const char **argv) {
    return PAM_SUCCESS;
}
