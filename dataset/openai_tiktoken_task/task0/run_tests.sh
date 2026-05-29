#!/bin/bash

set -e

# Cleanup function
test_cleanup() {
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git reset --hard HEAD 2>/dev/null || true
        git clean -fdx 2>/dev/null || true
    fi
}
trap test_cleanup EXIT INT TERM

usage() {
    echo "Usage: $0 <repo_path> <test_patch> [feature_patch]"
    exit 1
}

REPO_PATH="$1"
TEST_PATCH="$2"
FEATURE_PATCH="$3"

[[ -z "$REPO_PATH" || -z "$TEST_PATCH" ]] && usage
[[ ! -d "$REPO_PATH" ]] && { echo "Repository not found at $REPO_PATH"; exit 1; }
[[ ! -f "$TEST_PATCH" ]] && { echo "Test patch not found at $TEST_PATCH"; exit 1; }
[[ -n "$FEATURE_PATCH" && ! -f "$FEATURE_PATCH" ]] && { echo "Feature patch not found at $FEATURE_PATCH"; exit 1; }

TEST_PATCH="$(realpath "$TEST_PATCH")"
[[ -n "$FEATURE_PATCH" ]] && FEATURE_PATCH="$(realpath "$FEATURE_PATCH")"

cd "$REPO_PATH"

# Apply feature patch if provided
if [[ -n "$FEATURE_PATCH" ]]; then
    git apply --ignore-whitespace --ignore-space-change "$FEATURE_PATCH" || git apply --3way "$FEATURE_PATCH"
fi

git apply --ignore-whitespace --ignore-space-change "$TEST_PATCH" || git apply --3way "$TEST_PATCH"

# Install build system dependencies (Python, Rust, etc.)
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv curl build-essential
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y python3 python3-pip curl gcc make
elif command -v brew >/dev/null 2>&1; then
    brew install python curl
fi

# Install Rust if not present
if ! command -v cargo >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
fi

python3 -m venv .venv || { echo "Failed to create venv"; exit 1; }
source ".venv/bin/activate" || { echo "Failed to activate virtualenv"; exit 1; }

pip install -e . || { echo "Failed to install package"; exit 1; }
pip install pytest pytest-xdist regex hypothesis || { echo "Failed to install test dependencies"; exit 1; }

# Discover test files matching test_feature*.py, fallback to all tests if none found
if compgen -G "tests/test_feature*.py" > /dev/null; then
    UNIT_TEST_SPEC="tests/test_feature*.py"
else
    UNIT_TEST_SPEC="tests/"
fi

python -m pytest $UNIT_TEST_SPEC -v
exit $?
