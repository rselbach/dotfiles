#!/bin/bash
# macOS defaults configuration
# Run this script to apply system preferences
# Some changes require logout/restart to take effect

set -e

echo "Configuring macOS defaults..."

# Close any open System Preferences panes to prevent them from overriding settings
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# ============================================================================
# Global Settings
# ============================================================================

# Always show hidden files
defaults write NSGlobalDomain AppleShowAllFiles -bool true

# Disable automatic light/dark mode switching
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false

# Use dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ============================================================================
# Software Update
# ============================================================================

# Automatically install macOS updates
defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true

# ============================================================================
# Menu Bar
# ============================================================================

# Show 24-hour clock
defaults write com.apple.menuextra.clock Show24Hour -bool true

# Show battery percentage
defaults write com.apple.controlcenter BatteryShowPercentage -bool true

# ============================================================================
# Dock
# ============================================================================

# Don't automatically hide the Dock
defaults write com.apple.dock autohide -bool false

# Enable highlight hover effect for grid view stacks
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Position Dock on the left
defaults write com.apple.dock orientation -string "left"

# Don't show recent applications
defaults write com.apple.dock show-recents -bool false

# Set icon size
defaults write com.apple.dock tilesize -int 44

# Disable magnification
defaults write com.apple.dock magnification -bool false

# Magnified icon size (when magnification is enabled)
defaults write com.apple.dock largesize -int 48

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Genie minimize effect
defaults write com.apple.dock mineffect -string "genie"

# ============================================================================
# Finder
# ============================================================================

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar (breadcrumbs)
defaults write com.apple.finder ShowPathbar -bool true

# Remove items from trash after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# Show all file extensions
defaults write com.apple.finder AppleShowAllExtensions -bool true

# Show external drives on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

# Show removable media on desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show mounted servers on desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

# Show full POSIX path in window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true

# ============================================================================
# Login Window
# ============================================================================

# Disable guest user
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# ============================================================================
# Privacy & Advertising
# ============================================================================

# Disable personalized ads
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
defaults write com.apple.AdLib forceLimitAdTracking -bool true

# ============================================================================
# Desktop Services
# ============================================================================

# Don't create .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Don't create .DS_Store files on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ============================================================================
# Safari
# ============================================================================

# Disable AutoFill passwords (use 1Password instead)
defaults write com.apple.Safari AutoFillPasswords -bool false

# Enable Develop menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true

# ============================================================================
# TouchID for sudo (requires sudo)
# ============================================================================

SUDO_LOCAL="/etc/pam.d/sudo_local"
SUDO_LOCAL_TEMPLATE="/etc/pam.d/sudo_local.template"

# Remove dangling symlink if present (e.g., leftover from nix-darwin)
if [ -L "$SUDO_LOCAL" ] && [ ! -e "$SUDO_LOCAL" ]; then
    echo "Removing dangling sudo_local symlink..."
    sudo rm "$SUDO_LOCAL"
fi

if [ ! -f "$SUDO_LOCAL" ] || ! grep -q "pam_tid.so" "$SUDO_LOCAL"; then
    echo "Enabling TouchID for sudo..."
    if [ -f "$SUDO_LOCAL_TEMPLATE" ]; then
        # Copy template and enable TouchID
        sudo cp "$SUDO_LOCAL_TEMPLATE" "$SUDO_LOCAL"
        sudo sed -i '' 's/^#auth/auth/' "$SUDO_LOCAL"
    else
        echo "auth       sufficient     pam_tid.so" | sudo tee "$SUDO_LOCAL" > /dev/null
    fi
fi

# ============================================================================
# Apply changes
# ============================================================================

echo "Restarting affected applications..."

# Restart Dock
killall Dock 2>/dev/null || true

# Restart Finder
killall Finder 2>/dev/null || true

echo "Done! Some changes may require logout or restart to take effect."
