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
            # Remove safety flag if it exists
            [[ -f ".is_test_workspace" ]] && rm -f ".is_test_workspace" && echo "Removing .is_test_workspace"
            echo "CLEANUP: Repository restored to clean state"
        else
            echo "CLEANUP: Skipped - safety validation failed"
        fi
    fi
    # Always return to original directory
    cd "$ORIGINAL_DIR" 2>/dev/null || true
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

# Function to check if directory is inside an agent workspace
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

# Resolve target repository path and validate
TARGET_REPO_PATH="$(realpath "$REPO_PATH")"

# Change to target directory BEFORE setting up cleanup trap
cd "$TARGET_REPO_PATH" || { echo "ERROR: Cannot access repository at $TARGET_REPO_PATH"; exit 1; }

# SAFETY CHECK: Ensure this is an agent workspace before any git operations
if ! is_agent_workspace "$TARGET_REPO_PATH"; then
    echo "ERROR: Repository safety check failed!"
    echo "Directory: $TARGET_REPO_PATH"
    if [[ -f "$TARGET_REPO_PATH/.is_test_workspace" ]]; then
        echo "Missing required file: .is_test_workspace"
        echo "This repository is not marked as safe for testing operations."
        echo "If this is a test workspace, create the flag file manually."
        echo "If not, check why the evaluation is pointing to this directory."
    else
        parent_dir=$(basename "$(dirname "$TARGET_REPO_PATH")")
        echo "Parent directory: $parent_dir"
        echo "This repository is not inside an 'agent_workspace' directory."
        echo "Only repositories in agent_workspace directories are safe for testing operations."
        echo "If this should be a test workspace, check the directory structure."
    fi
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

export TRANSFORMERS_NO_TF=1
export TRANSFORMERS_NO_FLAX=1
export PANDAS_NO_USE_PYARROW=1
export LLAMA_CPP_FORCE_CPU=1          # disables Metal path in llama-cpp-python
export PYTORCH_ENABLE_MPS_FALLBACK=1  # harmless; avoids MPS surprises

uv venv
source .venv/bin/activate

uv sync
uv pip install -e .
uv pip install pytest pytest-xdist pytest_mock
uv pip install \
  pytest pytest-asyncio pytest-benchmark pytest-cov pytest-mock \
  torch transformers sentencepiece xgrammar llama-cpp-python==0.3.16


# Run test using the virtual environment's Python directly
echo "RUNNING_TESTS..."
.venv/bin/python - <<'PY'
import os, sys, pytest
code = pytest.main(["tests/backends/test_xgrammar.py", "-v", "--tb=short"])
if code == 0:
    # Tests passed; avoid native finalizers that crash on shutdown
    os._exit(0)
sys.exit(code)
PY

# Save package versions if tests passed successfully
echo "Saving package versions..."
uv pip freeze > "../requirements_validated.txt"
echo "Package versions saved to requirements_validated.txt"

echo "TEST_EXECUTION_COMPLETED"
