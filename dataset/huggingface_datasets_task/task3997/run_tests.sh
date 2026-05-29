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

# Get and validate input params
usage() {
    echo "Usage: $0 <repo_path> <test_patch> [feature_patch]"
    exit 1
}

REPO_PATH="$1"
TEST_PATCH="$2"
FEATURE_PATCH="$3"
TEST_PATH="tests/features/test_features.py"

[[ -z "$REPO_PATH" || -z "$TEST_PATCH" ]] && usage
[[ ! -d "$REPO_PATH" ]] && { echo "ERROR: Repository not found at $REPO_PATH"; exit 1; }
[[ ! -f "$TEST_PATCH" ]] && { echo "ERROR: Test patch not found at $TEST_PATCH"; exit 1; }
[[ -n "$FEATURE_PATCH" && ! -f "$FEATURE_PATCH" ]] && { echo "ERROR: Feature patch not found at $FEATURE_PATCH"; exit 1; }

TEST_PATCH="$(realpath "$TEST_PATCH")"
[[ -n "$FEATURE_PATCH" ]] && FEATURE_PATCH="$(realpath "$FEATURE_PATCH")"

cd "$REPO_PATH"

# Setup env
if [[ -n "$FEATURE_PATCH" ]]; then
    echo "APPLYING_FEATURE_PATCH: $FEATURE_PATCH"
    git apply --ignore-whitespace --ignore-space-change "$FEATURE_PATCH" || git apply --3way "$FEATURE_PATCH"
fi

echo "APPLYING_TEST_PATCH: $TEST_PATCH"
git apply --ignore-whitespace --ignore-space-change "$TEST_PATCH" || git apply --3way "$TEST_PATCH"

# Create and activate virtual environment
echo "Creating virtual environment..."
uv venv --python 3.12

# Activate the virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

echo "INSTALLING_DEPENDENCIES..."
uv pip install -e .
uv pip uninstall pyarrow
uv pip install "pyarrow==20.0.0"
uv pip install tensorflow-macos==2.16.* torch jax
uv pip install pytest pytest-xdist  # Common testing packages

# Run test
echo "RUNNING_TESTS..."
python -m pytest "$TEST_PATH" -v

echo "TEST_EXECUTION_COMPLETED"

