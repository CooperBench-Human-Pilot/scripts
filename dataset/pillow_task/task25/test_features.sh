#!/bin/bash

# Test script for pillow task25 - 5 feature implementation
# Usage: ./test_features.sh [1|2|3|4|5|all]

set -e

BASE_DIR="/Users/arpan/Desktop/CodeConflictBenchmark/dataset/pillow_task/task25"
REPO_PATH="$BASE_DIR/Pillow-pr-8852_main"

# Function to apply task patch and run tests
run_test_with_patch() {
    local test_patch="$1"

    # Clean and prepare repo
    cd "$REPO_PATH"
    git clean -fdx
    git reset --hard HEAD

    # Apply task patch (combined implementation with all 5 features)
    git apply "$BASE_DIR/task.patch"
    git status

    # Go back and run tests
    cd "$BASE_DIR"

    ./run_tests.sh "$REPO_PATH" "$test_patch"
}

case "${1:-all}" in
    "1")
        run_test_with_patch "$BASE_DIR/feature1/tests.patch"
        ;;
    "2")
        run_test_with_patch "$BASE_DIR/feature2/tests.patch"
        ;;
    "3")
        run_test_with_patch "$BASE_DIR/feature3/tests.patch"
        ;;
    "4")
        run_test_with_patch "$BASE_DIR/feature4/tests.patch"
        ;;
    "5")
        run_test_with_patch "$BASE_DIR/feature5/tests.patch"
        ;;
    "all"|"")
        run_test_with_patch "$BASE_DIR/feature1/tests.patch"
        run_test_with_patch "$BASE_DIR/feature2/tests.patch"
        run_test_with_patch "$BASE_DIR/feature3/tests.patch"
        run_test_with_patch "$BASE_DIR/feature4/tests.patch"
        run_test_with_patch "$BASE_DIR/feature5/tests.patch"
        ;;
    *)
        echo "Usage: $0 [1|2|3|4|5|all]"
        exit 1
        ;;
esac