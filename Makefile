CC := clang
CFLAGS := -fPIC -Wall -Wextra -O2 -fmodules -fblocks -Wno-deprecated-declarations -D_FORTIFY_SOURCE=0
LDFLAGS := -shared
FRAMEWORKS := -framework LocalAuthentication -framework Foundation
LIBS := -lpam -lobjc

# Directories
SRC_DIR := src
BUILD_DIR := build
SCRIPTS_DIR := scripts
INSTALL_DIR := /usr/local/lib/pam
HELPER_INSTALL_DIR := /usr/local/bin

# Files
PAM_SOURCE := $(SRC_DIR)/pam_touchid.m
PAM_OBJECT := $(BUILD_DIR)/pam_touchid.o
PAM_TARGET := $(BUILD_DIR)/pam_touchid.so

HELPER_SOURCE := $(SRC_DIR)/touchid-helper.m
HELPER_OBJECT := $(BUILD_DIR)/touchid-helper.o
HELPER_TARGET := $(BUILD_DIR)/touchid-helper

# Phony targets
.PHONY: all clean install uninstall build help

# Default target
all: build

# Help target
help:
	@echo "Touch ID for Sudo - macOS PAM Module"
	@echo "===================================="
	@echo "Available targets:"
	@echo "  make build       - Build the PAM module and helper"
	@echo "  make install     - Install the PAM module and helper (requires sudo)"
	@echo "  make uninstall   - Remove the PAM module and helper (requires sudo)"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make help        - Show this help message"

# Build target
build: $(PAM_TARGET) $(HELPER_TARGET)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(PAM_OBJECT): $(PAM_SOURCE) | $(BUILD_DIR)
	@echo "Compiling PAM module: $<"
	@$(CC) $(CFLAGS) -c $< -o $@ $(FRAMEWORKS)

$(PAM_TARGET): $(PAM_OBJECT)
	@echo "Linking: $@"
	@$(CC) $(LDFLAGS) $(PAM_OBJECT) -o $@ $(FRAMEWORKS) $(LIBS)
	@echo "✓ Build complete: $@"

$(HELPER_OBJECT): $(HELPER_SOURCE) | $(BUILD_DIR)
	@echo "Compiling helper: $<"
	@$(CC) $(CFLAGS) -c $< -o $@ $(FRAMEWORKS)

$(HELPER_TARGET): $(HELPER_OBJECT)
	@echo "Linking: $@"
	@$(CC) $(HELPER_OBJECT) -o $@ $(FRAMEWORKS) $(LIBS)
	@echo "✓ Build complete: $@"

# Install target
install: build
	@echo "Installing Touch ID for Sudo..."
	@if [ ! -d "$(INSTALL_DIR)" ]; then \
		echo "Error: $(INSTALL_DIR) does not exist"; \
		exit 1; \
	fi
	@sudo cp $(PAM_TARGET) $(INSTALL_DIR)/pam_touchid.so
	@sudo chmod 755 $(INSTALL_DIR)/pam_touchid.so
	@echo "✓ PAM module installed to $(INSTALL_DIR)/pam_touchid.so"
	@sudo cp $(HELPER_TARGET) $(HELPER_INSTALL_DIR)/touchid-helper
	@sudo chmod 755 $(HELPER_INSTALL_DIR)/touchid-helper
	@echo "✓ Helper installed to $(HELPER_INSTALL_DIR)/touchid-helper"
	@echo "Run './scripts/configure-sudo.sh' to enable Touch ID for sudo"

# Uninstall target
uninstall:
	@echo "Uninstalling Touch ID for Sudo..."
	@sudo rm -f $(INSTALL_DIR)/pam_touchid.so
	@sudo rm -f $(HELPER_INSTALL_DIR)/touchid-helper
	@echo "✓ Module and helper uninstalled"

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete"

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(OBJECT) $(TARGET)
	@echo "✓ Clean complete"

# Info target
info:
	@echo "System Information:"
	@echo "macOS Version: $$(sw_vers -productVersion)"
	@echo "Architecture: $$(uname -m)"
	@echo "Compiler: $$(clang --version | head -n 1)"
