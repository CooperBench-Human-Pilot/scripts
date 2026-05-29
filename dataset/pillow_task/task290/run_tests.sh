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

# Install build system dependencies
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y \
        libjpeg-dev zlib1g-dev libpng-dev libtiff-dev libfreetype6-dev \
        liblcms2-dev libopenjp2-7-dev libwebp-dev tcl8.6-dev tk8.6-dev \
        python3-tk
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y \
        libjpeg-devel zlib-devel libpng-devel libtiff-devel freetype-devel \
        lcms2-devel openjpeg2-devel libwebp-devel tcl-devel tk-devel \
        python3-tkinter
elif command -v brew >/dev/null 2>&1; then
    brew install jpeg zlib libpng libtiff freetype little-cms2 openjpeg webp tcl-tk
fi

echo "INSTALLING_DEPENDENCIES..."

if ! command -v python3 >/dev/null 2>&1; then
    echo "Installing Python..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3 python3-pip
    elif command -v brew >/dev/null 2>&1; then
        brew install python
    else
        echo "ERROR: Cannot install Python automatically. Please install Python manually."
        exit 1
    fi
fi

python3 -m venv .venv >/dev/null 2>&1
source ".venv/bin/activate"
pip install -e . >/dev/null 2>&1
pip install pytest pytest-xdist numpy >/dev/null 2>&1

# Run test
echo "RUNNING_TESTS..."
python -m pytest "Tests/test_image_quantize.py" -v 2>&1

echo "TEST_EXECUTION_COMPLETED"