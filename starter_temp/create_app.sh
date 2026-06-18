#!/bin/bash

# Flutter Mobile Starter - Create App Script
# Uses the existing working project as template

echo ""
echo "🚀 Flutter Mobile Starter - Create New App"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Python is available
if command -v python3 &> /dev/null; then
    python3 "$SCRIPT_DIR/create_app.py" "$@"
elif command -v python &> /dev/null; then
    python "$SCRIPT_DIR/create_app.py" "$@"
else
    echo "❌ Python is not installed or not in PATH"
    echo "   Please install Python 3.6+ to use this tool"
    exit 1
fi