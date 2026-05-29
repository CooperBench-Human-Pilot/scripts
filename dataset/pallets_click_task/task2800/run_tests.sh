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

cd "$REPO_PATH"

trap cleanup EXIT INT TERM

# Setup env
if [[ -n "$FEATURE_PATCH" ]]; then
    echo "APPLYING_FEATURE_PATCH: $FEATURE_PATCH"
    git apply --ignore-whitespace --ignore-space-change "$FEATURE_PATCH" || git apply --3way "$FEATURE_PATCH"
fi

echo "APPLYING_TEST_PATCH: $TEST_PATCH"
git apply --ignore-whitespace --ignore-space-change "$TEST_PATCH" || git apply --3way "$TEST_PATCH"

echo "INSTALLING_DEPENDENCIES..."

uv venv
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
.venv/bin/python -m pytest tests/test_shell_completion.py tests/test_context.py -v 2>&1

# Save package versions if tests passed successfully
echo "Saving package versions..."
uv pip freeze > "../requirements_validated.txt"
echo "Package versions saved to requirements_validated.txt"

echo "TEST_EXECUTION_COMPLETED"
