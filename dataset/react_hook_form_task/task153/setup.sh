#!/bin/bash

set -e

REPO_NAME="react-hook-form-pr-11214_main"
BASE_COMMIT="cec3267e12aaee01b6a17b657f9297021defdc50"

echo "Setting up React Hook Form repository for Task 153..."

# Clone or use existing repo
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/react-hook-form/react-hook-form.git "$REPO_NAME"
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