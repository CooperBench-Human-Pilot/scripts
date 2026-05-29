#!/bin/bash

set -e

REPO_NAME="Pillow-pr-5879_main"
BASE_COMMIT="cc927343dadc4d5c53afebba9c41fe02b6d7bbe4"

echo "Setting up Pillow repository for Task 290..."

# Clone or use existing repo
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/python-pillow/Pillow.git "$REPO_NAME"
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