#!/bin/bash
# Setup script for Task {number}: PR #{number} - Only change readonly if saved filename matches opened filename

REPO_NAME="click-pr-2800"
BASE_COMMIT="d8763b93021c416549b5f8b4b5497234619410db"

# Create a directory for the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/pallets/click "$REPO_NAME"
    cd "$REPO_NAME"
else
    echo "Repository directory already exists. Using existing clone."
    cd "$REPO_NAME"
    # Fetch latest changes
    git fetch origin
fi

# Checkout base commit
echo "Checking out base commit: $BASE_COMMIT"
git checkout "$BASE_COMMIT"

# Create a branch for our work
git branch -D "click_task2800" 2>/dev/null
git checkout -b "click_task2800"

git restore .
git restore --staged .

## GENERATE VENV

cd $REPO_NAME
uv venv
source .venv/bin/activate

if [ -f "uv.lock" ] || [ -f "pyproject.toml" ]; then
    echo "Installing dependencies from uv.lock..."
    uv sync
    # Install the package in editable mode with test dependencies
    echo "Installing test dependencies..."
    if uv pip install -e ".[test]" 2>/dev/null; then
        echo "Test dependencies installed successfully"
    else
        echo "Test dependencies not available, installing basic package and fallback test tools"
        uv pip install -e .
        uv pip install pytest pytest-xdist pytest_mock
    fi
else
    # Install with test dependencies if available, fallback to basic install
    if pip install -e ".[test]" 2>/dev/null; then
        echo "Test dependencies installed successfully"
    else
        echo "Test dependencies not available, installing basic package and fallback test tools"
        pip install -e .
        pip install pytest pytest-xdist pytest_mock
    fi
fi
