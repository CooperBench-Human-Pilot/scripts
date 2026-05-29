#!/bin/bash
# Setup script for Task {number}: PR #{number} - Only change readonly if saved filename matches opened filename

REPO_NAME="click-pr-2956"
BASE_COMMIT="5c1239b0116b66492cdd0848144ab3c78a04495a"

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
git branch -D "click_task2956" 2>/dev/null
git checkout -b "click_task2956"

git restore .
git restore --staged .
