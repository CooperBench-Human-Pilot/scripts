#!/bin/bash

set -e

TASK_DIR="/Users/arpan/Desktop/CodeConflictBenchmark/dataset/dottxt_ai_outlines_task/task1371"
REPO_DIR="$TASK_DIR/outlines-pr-1371"
COMBINED_PATCH="$TASK_DIR/combined.patch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Store original directory
ORIGINAL_DIR="$(pwd)"

cleanup() {
    cd "$ORIGINAL_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Function to reset the repository
reset_repo() {
    echo -e "${YELLOW}Resetting repository...${NC}"
    cd "$REPO_DIR"
    git reset --hard HEAD 2>/dev/null || true
    git clean -fdx 2>/dev/null || true
}

# Function to setup virtual environment
setup_venv() {
    echo -e "${YELLOW}Setting up virtual environment...${NC}"
    cd "$REPO_DIR"
    
    if [ ! -d ".venv" ]; then
        uv venv
    fi
    source .venv/bin/activate
    
    # Install package and test dependencies
    uv pip install -e ".[test]" 2>/dev/null || uv pip install -e .
    uv pip install pytest pytest-xdist pytest_mock
}

# Function to test a feature
test_feature() {
    local feature_num=$1
    local feature_dir="$TASK_DIR/feature${feature_num}"
    
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Testing Feature ${feature_num}${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    # Reset repo
    reset_repo
    
    # Apply combined patch
    if [ -f "$COMBINED_PATCH" ]; then
        echo "Applying combined patch..."
        cd "$REPO_DIR"
        git apply --ignore-whitespace --ignore-space-change "$COMBINED_PATCH" || git apply --3way "$COMBINED_PATCH"
    else
        echo -e "${RED}Combined patch not found at $COMBINED_PATCH${NC}"
        return 1
    fi
    
    # Apply test patch for this feature
    local test_patch="$feature_dir/tests.patch"
    if [ -f "$test_patch" ]; then
        echo "Applying test patch for feature ${feature_num}..."
        git apply --ignore-whitespace --ignore-space-change "$test_patch" || git apply --3way "$test_patch"
    else
        echo -e "${RED}Test patch not found at $test_patch${NC}"
        return 1
    fi
    
    # Setup virtual environment
    setup_venv
    
    # Run tests
    echo "Running tests for feature ${feature_num}..."
    cd "$REPO_DIR"
    source .venv/bin/activate
    
    if .venv/bin/python -m pytest tests/test_prompts.py -v 2>&1; then
        echo -e "${GREEN}Feature ${feature_num}: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Feature ${feature_num}: FAILED${NC}"
        return 1
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <feature_number|all> [feature_number...]"
    echo "Examples:"
    echo "  $0 1          # Test feature 1"
    echo "  $0 1 2 3      # Test features 1, 2, and 3"
    echo "  $0 all        # Test all features"
    exit 1
fi

# Track results
declare -a passed_features
declare -a failed_features

# If 'all' is specified, test all features
if [ "$1" = "all" ]; then
    features=(1 2 3 4)
else
    features=("$@")
fi

for feature in "${features[@]}"; do
    if test_feature "$feature"; then
        passed_features+=("$feature")
    else
        failed_features+=("$feature")
    fi
done

# Summary
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}SUMMARY${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ ${#passed_features[@]} -gt 0 ]; then
    echo -e "${GREEN}PASSED: ${passed_features[*]}${NC}"
fi

if [ ${#failed_features[@]} -gt 0 ]; then
    echo -e "${RED}FAILED: ${failed_features[*]}${NC}"
    exit 1
fi

echo -e "${GREEN}All tested features passed!${NC}"
exit 0

