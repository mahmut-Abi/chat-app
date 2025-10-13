#!/bin/bash
#
# Setup Git hooks for the project
#

echo "📦 Installing Git hooks..."
echo ""

# Check if hooks directory exists
if [ ! -d "scripts/hooks" ]; then
    echo "❌ Error: scripts/hooks directory not found!"
    exit 1
fi

# Copy pre-commit hook
if [ -f "scripts/hooks/pre-commit" ]; then
    cp scripts/hooks/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    echo "✅ Installed pre-commit hook"
else
    echo "⚠️  Warning: pre-commit hook not found"
fi

echo ""
echo "✅ Git hooks installation complete!"
echo ""
echo "Available hooks:"
echo "  • pre-commit: Runs flutter analyze before commit"
echo ""
echo "To skip hooks, use: git commit --no-verify"
