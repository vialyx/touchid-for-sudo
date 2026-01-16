# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-16

### Added
- Initial release of Touch ID for Sudo
- PAM module for Touch ID authentication on macOS
- Support for both Apple Silicon (ARM64) and Intel (x86_64) Macs
- Automated installation and configuration scripts
- Safe uninstallation with automatic backup restoration
- System status checking utility
- Comprehensive documentation and troubleshooting guide
- macOS package (.pkg) generation support
- Automatic retry logic for failed authentication attempts
- System logging for authentication events

### Features
- Biometric Touch ID authentication for sudo commands
- Password fallback (optional mode by default)
- LocalAuthentication framework integration
- Secure Enclave integration
- User-friendly installation experience
- Complete project reversibility

## [Unreleased]

### Planned
- Support for other authentication methods (Face ID on Mac Studio)
- Configuration profiles for MDM deployment
- Keychain integration for password management
- Shell integration enhancements
- GitHub Actions CI/CD pipeline
- Binary releases for easier installation
