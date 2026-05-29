#!/bin/bash

set -e

REPO_NAME="Pillow-pr-8852_main"
BASE_COMMIT="869aa5843c79c092db074b17234e792682eada41"

echo "Setting up Pillow repository for Task 25..."

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