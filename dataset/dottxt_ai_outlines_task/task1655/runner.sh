#!/bin/bash

set -e

# Cleanup function
cleanup() {
    echo "Cleaning up repository..."
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git reset --hard HEAD 2>/dev/null || true
        git clean -fdx 2>/dev/null || true
        echo "Repository cleaned."
    fi
}

trap cleanup EXIT INT TERM

# Get input params
TEST_PATCH="$1"
FEATURE_PATCH="$2"

if [[ -z "$TEST_PATCH" ]]; then
    echo "Usage: docker run -v \$(pwd):/patches <image> <test_patch> [feature_patch]"
    exit 1
fi

cd /workspace/repo

# Ensure we start with a clean state
echo "Ensuring clean repository state..."
git reset --hard HEAD
git clean -fdx

# Apply feature patch if provided
if [[ -n "$FEATURE_PATCH" ]]; then
    echo "Applying feature patch: $FEATURE_PATCH"
    if [[ -f "/patches/$FEATURE_PATCH" ]]; then
        git apply --ignore-whitespace --ignore-space-change "/patches/$FEATURE_PATCH" || git apply --3way "/patches/$FEATURE_PATCH"
        echo "Feature patch applied successfully."
    else
        echo "Error: Feature patch not found at /patches/$FEATURE_PATCH"
        exit 1
    fi
fi

# Apply test patch
echo "Applying test patch: $TEST_PATCH"
if [[ -f "/patches/$TEST_PATCH" ]]; then
    git apply --ignore-whitespace --ignore-space-change "/patches/$TEST_PATCH" || git apply --3way "/patches/$TEST_PATCH"
    echo "Test patch applied successfully."
else
    echo "Error: Test patch not found at /patches/$TEST_PATCH"
    exit 1
fi

# Set up Python environment using uv (SYSTEM PYTHON)
echo "Setting up Python environment with uv..."
# No need to create a venv, using system python with pre-installed packages

# Install dependencies
echo "Installing dependencies..."
# Use --system to install into the global environment, which is pre-populated by Dockerfile
if [ -f uv.lock ]; then
    echo "Syncing from uv.lock..."
    uv sync
else
    echo "No uv.lock found, installing manually..."
fi

# Try test-extras install, else fallback to base package
if uv pip install --system -e ".[test]" 2>/dev/null; then
    echo "Installed test extras"
else
    echo "Extras unavailable; installing base package"
    uv pip install --system -e .
fi

# Always install pytest tools
# These are already installed in the Dockerfile, this will be a no-op
uv pip install --system pytest pytest-xdist pytest_mock
echo "Test tools installed"

# Run tests with timeout
echo "Running tests..."
timeout 300 python -m pytest tests/types/test_custom_types.py -v

echo "Test execution completed!"

