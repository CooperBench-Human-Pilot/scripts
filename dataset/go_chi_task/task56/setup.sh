#!/bin/bash

set -e

REPO_NAME="chi-task56_main"
BASE_COMMIT="7f280968675bcc9f310008fc6b8abff0b923734c"

echo "Setting up chi repository for Task 56..."

# Clone or use existing repo
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/go-chi/chi "$REPO_NAME"
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