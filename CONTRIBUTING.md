# Contributing to Touch ID for Sudo

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Please be respectful and considerate when interacting with other community members.

## Ways to Contribute

1. **Report Bugs**: Found an issue? Please open a GitHub issue with details
2. **Suggest Features**: Have an idea? Share it in the discussions or issues
3. **Improve Documentation**: Help us write better guides and examples
4. **Submit Code**: Fix bugs or add features with pull requests
5. **Test**: Help test on different macOS versions and Mac models

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/touchid-for-sudo.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Test thoroughly
6. Commit with clear messages: `git commit -m "Add: description of changes"`
7. Push to your fork: `git push origin feature/your-feature`
8. Open a Pull Request

## Development Setup

```bash
# Clone the repository
git clone https://github.com/maksimvialykh/touchid-for-sudo.git
cd touchid-for-sudo

# Install dependencies
xcode-select --install

# Build the project
make build

# Test the build
./scripts/status.sh
```

## Code Style

- C code follows standard POSIX conventions
- Shell scripts use bash and conform to ShellCheck standards
- Comments should be clear and explain the "why", not just the "what"
- Use meaningful variable and function names

## Testing

Before submitting a PR:

1. Build the project: `make build`
2. Test installation: `make install`
3. Test configuration: `sudo ./scripts/configure-sudo.sh`
4. Test uninstallation: `sudo ./scripts/uninstall.sh`
5. Verify reversal works correctly

## Pull Request Process

1. Update documentation if needed
2. Ensure code builds without warnings
3. Test on both Apple Silicon and Intel Macs if possible
4. Write clear PR description explaining changes
5. Reference any related issues
6. Wait for review and address feedback

## Reporting Bugs

When reporting bugs, please include:

- macOS version
- Mac model and processor (Apple Silicon/Intel)
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant error messages or logs

## Questions?

Open an issue with the question tag or start a discussion on GitHub.

Thank you for contributing!
