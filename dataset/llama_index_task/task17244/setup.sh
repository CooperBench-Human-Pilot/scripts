#!/bin/bash
# Setup script for Task 17244: PR #17244 - fix: accept already base64-encoded data in ImageBlock

REPO_NAME="llama-index-pr-17244_main"
BASE_COMMIT="b004ea099f70e4c660b2d8e106d461d7aa78ed5f" 
MERGE_COMMIT="d9348e32fa0b99ab523125a43e351e69b9bbe140"
PR_NUMBER="17244"
FEATURE_NUMBER="1"

# Parse command line arguments
APPLY_PATCH=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a|--apply) APPLY_PATCH=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Create a directory for the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/run-llama/llama_index.git "$REPO_NAME"
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
git branch -D "code-conflict-bench" 2>/dev/null
git checkout -b "code-conflict-bench"

# Apply patch if requested
if [ "$APPLY_PATCH" = true ]; then
    echo "Applying patch..."
    git apply "../feature$FEATURE_NUMBER/feature.patch"
    echo "Patch applied successfully!"
else
    echo "Repository set up at the base commit."
    echo "To apply the patch, use: ./setup.sh --apply"
    echo "You can also apply the patch manually: git apply ../feature$FEATURE_NUMBER/feature.patch"
fi

echo 
echo "Quick references:"
echo "- Base commit: $BASE_COMMIT"
echo "- Merge commit: $MERGE_COMMIT"
echo "- To view the complete diff: git diff $BASE_COMMIT..$MERGE_COMMIT"