#!/bin/bash
# Setup script for Task 8394: PR #8394 - compute cache key once
set -euo pipefail

echo "Setting up DSPy repository for Task 8587..."

REPO_NAME="dspy-pr-8587_main"
BASE_COMMIT="80412ce96d70fdb64dcf2c63940f511d6f89ca44"
MERGE_COMMIT="ab7ac0b916492eefe7da356310d4bce5283c0e7c"
PR_NUMBER="8587"

# Create a directory for the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/stanfordnlp/dspy.git "$REPO_NAME"
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

# Ensure a clean working tree at the base commit
git reset --hard "$BASE_COMMIT"
git clean -fdx

# Create a branch for our work
# Ignore failure if the branch does not exist yet
git branch -D "code-conflict-bench" 2>/dev/null || true
git checkout -b "code-conflict-bench"

echo
echo "Setup completed successfully!"
echo "Repository location: $(pwd)"
echo "- Repository: $REPO_NAME"
echo "- Base commit: $BASE_COMMIT"
echo "- Merge commit: $MERGE_COMMIT"
echo "- Current branch: code-conflict-bench"
echo
echo "You can now run tests using run_tests.sh"
