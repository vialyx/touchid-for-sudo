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

# Files
SOURCE := $(SRC_DIR)/pam_touchid.m
OBJECT := $(BUILD_DIR)/pam_touchid.o
TARGET := $(BUILD_DIR)/pam_touchid.so

# Phony targets
.PHONY: all clean install uninstall build help

# Default target
all: build

# Help target
help:
	@echo "Touch ID for Sudo - macOS PAM Module"
	@echo "===================================="
	@echo "Available targets:"
	@echo "  make build       - Build the PAM module"
	@echo "  make install     - Install the PAM module (requires sudo)"
	@echo "  make uninstall   - Remove the PAM module (requires sudo)"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make help        - Show this help message"

# Build target
build: $(TARGET)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(OBJECT): $(SOURCE) | $(BUILD_DIR)
	@echo "Compiling: $<"
	@$(CC) $(CFLAGS) -c $< -o $@ $(FRAMEWORKS)

$(TARGET): $(OBJECT)
	@echo "Linking: $@"
	@$(CC) $(LDFLAGS) $(OBJECT) -o $@ $(FRAMEWORKS) $(LIBS)
	@echo "✓ Build complete: $@"

# Install target
install: build
	@echo "Installing Touch ID for Sudo..."
	@if [ ! -d "$(INSTALL_DIR)" ]; then \
		echo "Error: $(INSTALL_DIR) does not exist"; \
		exit 1; \
	fi
	@sudo cp $(TARGET) $(INSTALL_DIR)/pam_touchid.so
	@sudo chmod 755 $(INSTALL_DIR)/pam_touchid.so
	@echo "✓ Module installed to $(INSTALL_DIR)/pam_touchid.so"
	@echo "Run './scripts/configure-sudo.sh' to enable Touch ID for sudo"

# Uninstall target
uninstall:
	@echo "Uninstalling Touch ID for Sudo..."
	@sudo rm -f $(INSTALL_DIR)/pam_touchid.so
	@echo "✓ Module uninstalled"

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
