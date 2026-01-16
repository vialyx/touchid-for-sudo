class TouchidForSudo < Formula
  desc "Enable Touch ID authentication for sudo on macOS"
  homepage "https://github.com/vialyx/touchid-for-sudo"
  url "https://github.com/vialyx/touchid-for-sudo/releases/download/v1.0.0/TouchID-for-Sudo-1.0.0.pkg"
  sha256 "YOUR_SHA256_HERE"
  version "1.0.0"

  depends_on :macos => ">= :catalina"
  depends_on "xcode-select"

  def install
    # Extract .pkg installer
    system "pkgutil --expand-full", cached_download, buildpath/"TouchID.pkg"
    
    # Copy the PAM module
    lib.install "#{buildpath}/TouchID.pkg/Payload/usr/local/lib/pam/pam_touchid.so"
    
    # Copy helper scripts
    bin.install "#{buildpath}/TouchID.pkg/Scripts/preinstall" => "touchid-configure"
    bin.install "#{buildpath}/TouchID.pkg/Scripts/postinstall" => "touchid-status"
    bin.install "#{buildpath}/TouchID.pkg/Scripts/postinstall" => "touchid-uninstall"
  end

  def post_install
    puts "╔════════════════════════════════════════════════════════════════╗"
    puts "║  Touch ID for Sudo - Installation Complete!                 ║"
    puts "╚════════════════════════════════════════════════════════════════╝"
    puts ""
    puts "Next steps:"
    puts "  1. Run: sudo touchid-configure"
    puts "  2. Test: sudo whoami"
    puts "  3. Check status: touchid-status"
    puts ""
    puts "To remove: brew uninstall touchid-for-sudo"
    puts ""
  end

  test do
    system "#{bin}/touchid-status"
  end
end
