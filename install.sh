#!/bin/bash

set -e

echo "Claude Usage Tracker - SwiftBar Plugin Installer"
echo "================================================="
echo ""

# Check for Bun
if ! command -v bun &> /dev/null; then
    echo "Bun is required but not installed."
    echo "Install it with: curl -fsSL https://bun.sh/install | bash"
    echo "Or via Homebrew: brew install oven-sh/bun/bun"
    exit 1
fi
echo "✓ Bun found: $(which bun)"

# Check for SwiftBar
if ! [ -d "/Applications/SwiftBar.app" ]; then
    echo ""
    echo "SwiftBar is not installed."
    read -p "Would you like to install it via Homebrew? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install swiftbar
    else
        echo "Please install SwiftBar manually from https://github.com/swiftbar/SwiftBar"
        exit 1
    fi
fi
echo "✓ SwiftBar found"

# Check for Claude Code credentials
if ! security find-generic-password -s "Claude Code-credentials" -w &> /dev/null; then
    echo ""
    echo "⚠ Claude Code credentials not found in Keychain."
    echo "Make sure you're logged into Claude Code (run 'claude' in terminal)."
    echo "The plugin will show an error until you authenticate."
fi

# Create plugins directory if it doesn't exist
PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/plugins"
mkdir -p "$PLUGIN_DIR"

# Copy plugin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/claude-usage.5m.sh" "$PLUGIN_DIR/"
chmod +x "$PLUGIN_DIR/claude-usage.5m.sh"

echo "✓ Plugin installed to: $PLUGIN_DIR/claude-usage.5m.sh"
echo ""

# Check if SwiftBar is configured
if ! defaults read com.ameba.SwiftBar PluginDirectory &> /dev/null; then
    echo "SwiftBar needs to be configured with a plugins directory."
    echo "1. Open SwiftBar from Applications"
    echo "2. When prompted, select: $PLUGIN_DIR"
    echo ""
fi

# Offer to open SwiftBar
read -p "Would you like to open/restart SwiftBar now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    killall SwiftBar 2>/dev/null || true
    sleep 1
    open -a SwiftBar
    echo "✓ SwiftBar started"
fi

echo ""
echo "Installation complete!"
echo "You should see the Claude usage indicator in your menu bar."
echo ""
echo "If you don't see it:"
echo "  1. Make sure SwiftBar is running"
echo "  2. Click SwiftBar icon → Plugin Browser → Enable claude-usage"
echo "  3. Or right-click SwiftBar → Refresh All"
