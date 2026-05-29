#!/bin/bash

set -e

# Store original directory for safety
ORIGINAL_DIR="$(pwd)"
CLEANUP_ENABLED=false

# Safe cleanup function that validates directory
cleanup() {
    if [[ "$CLEANUP_ENABLED" == "true" ]]; then
        echo "CLEANING_UP: Restoring repository to original state..."
        # Verify we're in the intended target directory AND it's an agent workspace
        if [[ "$(pwd)" == "$TARGET_REPO_PATH" ]] && 
           git rev-parse --is-inside-work-tree > /dev/null 2>&1 && 
           is_agent_workspace "$TARGET_REPO_PATH"; then
            git reset --hard HEAD 2>/dev/null || true
            git clean -fdx 2>/dev/null || true
            echo "CLEANUP: Repository restored to clean state"
        else
            echo "CLEANUP: Skipped - safety validation failed"
        fi
    fi
    # Always return to original directory
    cd "$ORIGINAL_DIR" 2>/dev/null || true
}

is_agent_workspace() {
    local dir="$1"
    local parent_dir
    parent_dir=$(basename "$(dirname "$dir")")
    if [[ "$parent_dir" == "agent_workspace" ]]; then
        return 0
    else
        return 1
    fi
}

# Get and validate input params
usage() {
    echo "Usage: $0 <repo_path> <test_patch> [feature_patch]"
    exit 1
}

REPO_PATH="$1"
TEST_PATCH="$2"
FEATURE_PATCH="$3"

[[ -z "$REPO_PATH" || -z "$TEST_PATCH" ]] && usage
[[ ! -d "$REPO_PATH" ]] && { echo "ERROR: Repository not found at $REPO_PATH"; exit 1; }
[[ ! -f "$TEST_PATCH" ]] && { echo "ERROR: Test patch not found at $TEST_PATCH"; exit 1; }
[[ -n "$FEATURE_PATCH" && ! -f "$FEATURE_PATCH" ]] && { echo "ERROR: Feature patch not found at $FEATURE_PATCH"; exit 1; }

TEST_PATCH="$(realpath "$TEST_PATCH")"
[[ -n "$FEATURE_PATCH" ]] && FEATURE_PATCH="$(realpath "$FEATURE_PATCH")"

# Resolve target repository path and validate
TARGET_REPO_PATH="$(realpath "$REPO_PATH")"

# Change to target directory BEFORE setting up cleanup trap
cd "$TARGET_REPO_PATH" || { echo "ERROR: Cannot access repository at $TARGET_REPO_PATH"; exit 1; }

# SAFETY CHECK: Ensure this is an agent workspace before any git operations
if ! is_agent_workspace "$TARGET_REPO_PATH"; then
    PARENT_DIR=$(basename "$(dirname "$TARGET_REPO_PATH")")
    echo "ERROR: Repository safety check failed!"
    echo "Directory: $TARGET_REPO_PATH"
    echo "Parent directory: $PARENT_DIR"
    echo "This repository is not inside an 'agent_workspace' directory."
    echo "Only repositories in agent_workspace directories are safe for testing operations."
    echo "If this should be a test workspace, check the directory structure."
    exit 1
fi

# Only enable cleanup after we are safely in the target directory
CLEANUP_ENABLED=true
trap cleanup EXIT INT TERM
[[ -n "$FEATURE_PATCH" ]] && FEATURE_PATCH="$(realpath "$FEATURE_PATCH")"


# Setup env
if [[ -n "$FEATURE_PATCH" ]]; then
    echo "APPLYING_FEATURE_PATCH: $FEATURE_PATCH"
    git apply --ignore-whitespace --ignore-space-change "$FEATURE_PATCH" || git apply --3way "$FEATURE_PATCH"
fi

echo "APPLYING_TEST_PATCH: $TEST_PATCH"
git apply --ignore-whitespace --ignore-space-change "$TEST_PATCH" || git apply --3way "$TEST_PATCH"

echo "INSTALLING_DEPENDENCIES..."
uv venv --python 3.11
source .venv/bin/activate

[ -f uv.lock ] && { echo "Syncing from uv.lock…"; uv sync; }

# Try test-extras install, else fallback to base package
if uv pip install -e ".[test]" 2>/dev/null; then
  echo "Installed test extras"
else
  echo "Extras unavailable; installing base package"
  uv pip install -e .
fi

# Always install pytest tools
uv pip install pytest pytest-xdist pytest_mock \
  && echo "Test tools installed"

# Run test using the virtual environment's Python directly
echo "RUNNING_TESTS..."
python -m pytest tests/test_loader.py -v 2>&1

# Save package versions if tests passed successfully
echo "Saving package versions..."
uv pip freeze > "../requirements_validated.txt"
echo "Package versions saved to requirements_validated.txt"

echo "TEST_EXECUTION_COMPLETED"
