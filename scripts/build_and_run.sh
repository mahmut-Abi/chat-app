#!/bin/bash

# Build and Run Script for Chat App

set -e

echo "🚀 Chat App - Build & Run Script"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Generate code
echo "🔧 Generating code (Freezed, JSON serialization)..."
flutter pub run build_runner build --delete-conflicting-outputs

if [ $? -ne 0 ]; then
    echo "❌ Code generation failed"
    exit 1
fi

echo "✅ Code generated successfully"
echo ""

# Ask user which platform to run
echo "Select platform to run:"
echo "1) Web (Chrome)"
echo "2) Desktop (macOS)"
echo "3) Desktop (Windows)"
echo "4) Desktop (Linux)"
echo "5) Mobile (connected device)"
echo "6) Run tests"
echo "7) Format code"
read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo "🌐 Running on Web..."
        flutter run -d chrome
        ;;
    2)
        echo "🖥️  Running on macOS..."
        flutter run -d macos
        ;;
    3)
        echo "🖥️  Running on Windows..."
        flutter run -d windows
        ;;
    4)
        echo "🖥️  Running on Linux..."
        flutter run -d linux
        ;;
    5)
        echo "📱 Running on connected device..."
        flutter run
        ;;
    6)
        echo "🧪 Running tests..."
        flutter test
        ;;
    7)
        echo "✨ Formatting code..."
        flutter format .
        echo "✅ Code formatted"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
