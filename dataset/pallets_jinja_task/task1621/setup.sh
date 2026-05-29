#!/bin/bash
# Setup script for Task {number}: PR #{number} - Only change readonly if saved filename matches opened filename

REPO_NAME="jinja-pr-1621"
BASE_COMMIT="a2920752fd111c2d52c88eb57487667b3cf0ea7b"

# Create a directory for the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/pallets/jinja "$REPO_NAME"
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
git branch -D "jinja_task1621" 2>/dev/null
git checkout -b "jinja_task1621"

git restore .
git restore --staged .

## GENERATE VENV
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
