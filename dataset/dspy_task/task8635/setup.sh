#!/bin/bash
# Setup script for Task 8635: PR #8635 - MIPROv2 teleprompt patches
set -euo pipefail

echo "Setting up DSPy repository for Task 8635..."

REPO_NAME="dspy-pr-8635_main"
BASE_COMMIT="8f773dc75e34da21b89480e8bc71df503d5ab5fc"
PR_NUMBER="8635"

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
echo "- Current branch: code-conflict-bench"
echo
echo "You can now run tests using run_tests.sh"
