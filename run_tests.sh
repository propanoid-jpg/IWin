#!/bin/bash
# Test runner script for Linux/Mac
# Requires Lua 5.1 and Busted to be installed

echo "========================================"
echo "IWin External Test Runner"
echo "========================================"
echo ""

# Check if Lua is installed
if ! command -v lua &> /dev/null; then
    echo "ERROR: Lua not found in PATH"
    echo "Please install Lua 5.1"
    exit 1
fi

# Check if Busted is installed
if ! command -v busted &> /dev/null; then
    echo "ERROR: Busted not found in PATH"
    echo "Please install: luarocks install busted"
    exit 1
fi

echo "Running external unit tests..."
echo ""

busted --verbose tests/

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "All tests passed!"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "Tests failed!"
    echo "========================================"
    exit 1
fi
