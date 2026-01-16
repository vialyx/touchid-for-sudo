/*
 * Touch ID Helper - User-space process for biometric authentication
 * Runs with user privileges and communicates with PAM module via socket
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <signal.h>
#include <syslog.h>
#include <LocalAuthentication/LocalAuthentication.h>
#include <Foundation/Foundation.h>

#define SOCKET_PATH "/tmp/touchid-auth.sock"
#define SOCKET_TIMEOUT 60

int main(int argc, const char *argv[]) {
    openlog("touchid-helper", LOG_PID, LOG_USER);
    syslog(LOG_NOTICE, "Touch ID Helper started (uid=%d, gid=%d)", getuid(), getgid());
    
    /* Create and bind Unix domain socket */
    int server_sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server_sock < 0) {
        syslog(LOG_ERR, "Failed to create socket");
        perror("socket");
        return 1;
    }
    
    /* Remove old socket file if it exists */
    unlink(SOCKET_PATH);
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);
    
    if (bind(server_sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        syslog(LOG_ERR, "Failed to bind socket");
        perror("bind");
        close(server_sock);
        return 1;
    }
    
    /* Set restrictive permissions (only owner can access) */
    chmod(SOCKET_PATH, 0600);
    
    if (listen(server_sock, 1) < 0) {
        syslog(LOG_ERR, "Failed to listen on socket");
        perror("listen");
        close(server_sock);
        return 1;
    }
    
    syslog(LOG_DEBUG, "Socket bound to %s and listening", SOCKET_PATH);
    
    /* Accept single connection and process authentication request */
    struct sockaddr_un client_addr;
    socklen_t client_len = sizeof(client_addr);
    
    int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &client_len);
    if (client_sock < 0) {
        syslog(LOG_ERR, "Failed to accept connection");
        perror("accept");
        close(server_sock);
        return 1;
    }
    
    syslog(LOG_DEBUG, "Connection accepted from PAM module");
    
    /* Initialize Autorelease Pool */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    /* Perform Touch ID authentication */
    LAContext *context = [[LAContext alloc] init];
    if (context == nil) {
        syslog(LOG_ERR, "Failed to create LAContext");
        const char *response = "FAIL";
        write(client_sock, response, strlen(response));
        close(client_sock);
        close(server_sock);
        [pool drain];
        closelog();
        return 1;
    }
    
    syslog(LOG_DEBUG, "LAContext created successfully");
    
    /* Perform biometric authentication */
    __block BOOL authSuccess = NO;
    __block NSError *authError = nil;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    syslog(LOG_DEBUG, "Calling evaluatePolicy for user authentication");
    
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
            localizedReason:@"Authenticate with Touch ID for sudo"
                     reply:^(BOOL success, NSError *error) {
        syslog(LOG_DEBUG, "evaluatePolicy callback: success=%d, error=%s", success, 
               error ? [[error description] UTF8String] : "none");
        authSuccess = success;
        if (error) {
            authError = [error retain];
        }
        dispatch_semaphore_signal(sema);
    }];
    
    /* Wait for authentication to complete */
    syslog(LOG_DEBUG, "Waiting for Touch ID response...");
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    syslog(LOG_DEBUG, "Touch ID response received (success=%d)", authSuccess);
    
    /* Send result back to PAM module */
    const char *response;
    if (authSuccess) {
        syslog(LOG_NOTICE, "✓ Touch ID authentication SUCCESSFUL");
        response = "SUCCESS";
    } else {
        if (authError) {
            LAError errorCode = [authError code];
            NSString *errorDesc = [authError localizedDescription];
            syslog(LOG_WARNING, "Authentication failed: error=%ld (%s)", 
                   (long)errorCode, [errorDesc UTF8String]);
            [authError release];
        }
        syslog(LOG_NOTICE, "Touch ID authentication failed - user can try password");
        response = "CANCEL";  /* Treat failures as cancellation to allow password fallback */
    }
    
    syslog(LOG_DEBUG, "Sending response: %s", response);
    write(client_sock, response, strlen(response));
    
    /* Cleanup */
    close(client_sock);
    close(server_sock);
    unlink(SOCKET_PATH);
    
    [context release];
    [pool drain];
    closelog();
    
    return 0;
}
