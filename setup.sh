#!/bin/bash

# ============================================
# Contractor Must Do - Xcode Project Setup
# ============================================
# This script generates the Xcode project using xcodegen
#
# Prerequisites:
#   - macOS 13+ (Ventura or later)
#   - Xcode 15+ installed
#   - Homebrew (will be installed if missing)
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
# ============================================

set -e

echo "🔧 Contractor Must Do - Project Setup"
echo "======================================"
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Error: This script must be run on macOS"
    echo "   iOS apps can only be built on macOS with Xcode."
    exit 1
fi

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed"
    echo "   Please install Xcode from the App Store"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -1)"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "✅ Homebrew found"

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing xcodegen..."
    brew install xcodegen
fi

echo "✅ xcodegen found: $(xcodegen --version)"

# Generate the Xcode project
echo ""
echo "🏗️  Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Project generated successfully!"
echo ""
echo "======================================"
echo "📱 Next Steps:"
echo "======================================"
echo ""
echo "1. Open the project:"
echo "   open ContractorMustDo.xcodeproj"
echo ""
echo "2. Select your development team:"
echo "   - Click on 'ContractorMustDo' in the navigator"
echo "   - Select 'Signing & Capabilities' tab"
echo "   - Choose your Team under 'Signing'"
echo ""
echo "3. Run the app:"
echo "   - Select an iOS Simulator (iPhone 15 recommended)"
echo "   - Press Cmd+R or click the Play button"
echo ""
echo "4. Run tests:"
echo "   - Press Cmd+U or Product → Test"
echo ""
echo "======================================"
echo "🎉 Setup complete! Happy coding!"
echo "======================================"
