/*
 * PAM module for Touch ID authentication on macOS
 * Allows using Touch ID instead of password for sudo authentication
 *
 * Communicates with touchid-helper (user-space) for biometric authentication
 * This ensures the helper runs with user privileges to access biometric data
 *
 * Compile: gcc -fPIC -shared -o pam_touchid.so pam_touchid.m -lpam
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <signal.h>
#include <syslog.h>
#include <security/pam_appl.h>
#include <security/pam_modules.h>

#define PAM_TOUCHID_MAX_RETRIES 3
#define SOCKET_PATH "/tmp/touchid-auth.sock"
#define HELPER_PATH "/usr/local/bin/touchid-helper"
#define SOCKET_TIMEOUT 60

/* Use syslog instead of pam_syslog */
#define pam_syslog(h, p, f, ...) syslog(p, f, ##__VA_ARGS__)

/*
 * authenticate_via_helper - Communicate with user-space helper for biometric auth
 * 
 * Returns:
 *   PAM_SUCCESS - Authentication successful
 *   PAM_IGNORE  - User cancelled or authentication not available (allow password)
 *   PAM_AUTH_ERR - Error during helper communication
 */
static int authenticate_via_helper(pam_handle_t *pamh, const char *user) {
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Starting helper authentication for user %s", user);
    
    /* Get user info to switch context */
    struct passwd *pwd = getpwnam(user);
    if (pwd == NULL) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to get user info for %s", user);
        return PAM_USER_UNKNOWN;
    }
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: User %s has uid=%d, gid=%d", user, pwd->pw_uid, pwd->pw_gid);
    
    /* Fork process to run helper as user */
    pid_t pid = fork();
    if (pid < 0) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to fork helper process");
        return PAM_AUTH_ERR;
    }
    
    if (pid == 0) {
        /* Child process - run helper as user */
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Child process starting, switching to uid=%d", pwd->pw_uid);
        
        /* Set up environment for user context */
        if (setgid(pwd->pw_gid) < 0) {
            pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to setgid");
            _exit(1);
        }
        
        if (setuid(pwd->pw_uid) < 0) {
            pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to setuid");
            _exit(1);
        }
        
        pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Running helper as uid=%d", getuid());
        
        /* Execute helper */
        execl(HELPER_PATH, "touchid-helper", NULL);
        
        /* If exec fails */
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to execute helper: %s", HELPER_PATH);
        perror("execl");
        _exit(1);
    }
    
    /* Parent process - wait for helper to start and accept connection */
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Parent process waiting for helper to be ready");
    
    sleep(1);  /* Give helper time to start and bind socket */
    
    /* Connect to helper socket */
    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to create socket");
        kill(pid, SIGTERM);
        return PAM_AUTH_ERR;
    }
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Connecting to helper socket at %s", SOCKET_PATH);
    
    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        pam_syslog(pamh, LOG_ERR, "pam_touchid: Failed to connect to helper socket");
        close(sock);
        kill(pid, SIGTERM);
        return PAM_AUTH_ERR;
    }
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Connected to helper, waiting for authentication result");
    
    /* Read response from helper */
    char response[32] = {0};
    ssize_t n = read(sock, response, sizeof(response) - 1);
    
    close(sock);
    
    /* Wait for helper process to exit */
    int status;
    waitpid(pid, &status, 0);
    
    pam_syslog(pamh, LOG_DEBUG, "pam_touchid: Helper returned response: %s", response);
    
    if (n <= 0) {
        pam_syslog(pamh, LOG_WARNING, "pam_touchid: Failed to read response from helper");
        return PAM_AUTH_ERR;
    }
    
    /* Parse response */
    if (strncmp(response, "SUCCESS", n) == 0) {
        pam_syslog(pamh, LOG_NOTICE, "pam_touchid: ✓ Touch ID authentication SUCCESSFUL");
        return PAM_SUCCESS;
    } else if (strncmp(response, "CANCEL", n) == 0) {
        pam_syslog(pamh, LOG_NOTICE, "pam_touchid: Touch ID cancelled/unavailable - falling back to password");
        return PAM_IGNORE;
    } else {
        pam_syslog(pamh, LOG_WARNING, "pam_touchid: Unknown response from helper: %s", response);
        return PAM_AUTH_ERR;
    }
}
/*
 * pam_sm_authenticate - Perform authentication via Touch ID helper
 */
PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                                    int argc, const char **argv) {
    const char *user;
    int retval;
    
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
    
    /* Authenticate via user-space helper */
    return authenticate_via_helper(pamh, user);
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
