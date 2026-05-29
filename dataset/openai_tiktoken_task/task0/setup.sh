#!/bin/bash

set -e

REPO_NAME="tiktoken-pr-0_main"
BASE_COMMIT="4560a8896f5fb1d35c6f8fd6eee0399f9a1a27ca"

echo "Setting up tiktoken repository for Task 0..."

# Clone or use existing repo
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/openai/tiktoken "$REPO_NAME"
    cd "$REPO_NAME"
else
    echo "Repository directory already exists. Using existing clone."
    cd "$REPO_NAME"
    git fetch origin
    git reset --hard HEAD
    git clean -fdx
fi

# Checkout base commit
echo "Checking out base commit: $BASE_COMMIT"
git checkout "$BASE_COMMIT"

echo "Setup completed successfully!"
echo "Repository location: $(pwd)"
echo "Base commit: $BASE_COMMIT"