#!/bin/bash

set -e

# Cleanup function
cleanup() {
    echo "Cleaning up repository..."
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        CURRENT_BRANCH_OR_COMMIT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        echo "Resetting to HEAD ($CURRENT_BRANCH_OR_COMMIT) and cleaning..."
        git reset --hard HEAD || true
        git clean -fdx || true
        echo "Repository cleaned."
    else
        echo "Not inside a git repository, skipping git cleanup."
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

# Apply test patch with better error handling
echo "Applying test patch..."
if [[ -f "/patches/$TEST_PATCH" ]]; then
    if ! git apply --check "/patches/$TEST_PATCH" 2>/dev/null; then
        echo "Warning: Patch check failed. Attempting to apply anyway..."
    fi
    
    if ! git apply "/patches/$TEST_PATCH"; then
        echo "Error: Failed to apply test patch. Repository state may not match expected base commit."
        echo "Patch file: /patches/$TEST_PATCH"
        exit 1
    fi
    echo "Test patch applied successfully."
else
    echo "Error: Test patch not found at /patches/$TEST_PATCH"
    exit 1
fi

# Optionally apply feature patch
if [[ -n "$FEATURE_PATCH" ]]; then
    echo "Applying feature patch..."
    if [[ -f "/patches/$FEATURE_PATCH" ]]; then
        if ! git apply --check "/patches/$FEATURE_PATCH" 2>/dev/null; then
            echo "Warning: Feature patch check failed. Attempting to apply anyway..."
        fi
        if ! git apply "/patches/$FEATURE_PATCH"; then
            echo "Error: Failed to apply feature patch."
            echo "Patch file: /patches/$FEATURE_PATCH"
            exit 1
        fi
        echo "Feature patch applied successfully."
    else
        echo "Error: Feature patch not found at /patches/$FEATURE_PATCH"
        exit 1
    fi
fi

# Set up Python environment using uv (SYSTEM PYTHON)
echo "Setting up Python environment with uv..."
# uv venv -- removed to use system python
# source .venv/bin/activate -- removed

# Install dependencies (incremental update)
echo "Installing dependencies..."
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
uv pip install --system pytest pytest-xdist pytest_mock
echo "Test tools installed"

# Run tests with timeout
echo "Running tests..."
timeout 300 python3 -m pytest tests/test_prompts.py -v

echo "Test execution completed!"
