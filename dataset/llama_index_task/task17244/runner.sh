#!/bin/bash

set -e

# Cleanup function
cleanup() {
    echo "CLEANING_UP: Restoring repository to original state..."
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git reset --hard HEAD 2>/dev/null || true
        git clean -fdx 2>/dev/null || true
        echo "CLEANUP: Repository restored to clean state"
    fi
}

trap cleanup EXIT INT TERM

# Get input params
TEST_PATCH="$1"
FEATURE_PATCH="$2"
TEST_PATH="llama-index-core/tests/base/llms/test_types.py"

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
# No need to create a venv, using system python with pre-installed packages

# Install dependencies
echo "Installing dependencies..."
uv pip install --system -r pyproject.toml || uv pip install --system -e .
uv pip install --system pytest pytest-xdist openai # Common testing packages

# Run tests with timeout
echo "Running tests..."
timeout 300 python -m pytest "$TEST_PATH" -v

echo "Test execution completed!"

