#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PATH="$SCRIPT_DIR/chi-task26_main"
COMBINED_PATCH="$SCRIPT_DIR/combined.patch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

test_feature() {
    local feature_num=$1
    local test_patch="$SCRIPT_DIR/feature${feature_num}/tests.patch"
    
    echo "========================================"
    echo "Testing Feature $feature_num"
    echo "========================================"
    
    # Reset repo
    cd "$REPO_PATH"
    git reset --hard HEAD 2>/dev/null
    git clean -fdx 2>/dev/null
    
    # Apply combined patch
    if ! git apply --ignore-whitespace "$COMBINED_PATCH" 2>/dev/null; then
        echo -e "${RED}Failed to apply combined.patch${NC}"
        return 1
    fi
    
    # Apply test patch
    if ! git apply --ignore-whitespace "$test_patch" 2>/dev/null; then
        echo -e "${RED}Failed to apply tests.patch for feature $feature_num${NC}"
        return 1
    fi
    
    # Extract test function names from patch
    TEST_FUNCS=$(grep -o "func Test[a-zA-Z0-9_]*" "$test_patch" 2>/dev/null | sed 's/func //' | sort -u | tr '\n' '|' | sed 's/|$//')
    
    # Run tests
    echo "Running tests: $TEST_FUNCS"
    if [ -n "$TEST_FUNCS" ]; then
        if go test -v -run "$TEST_FUNCS" ./... 2>&1; then
            echo -e "${GREEN}Feature $feature_num: PASSED${NC}"
            return 0
        else
            echo -e "${RED}Feature $feature_num: FAILED${NC}"
            return 1
        fi
    else
        echo "No test functions found"
        return 1
    fi
}

# Test all features
RESULTS=()
for i in 1 2 3 4; do
    if test_feature $i; then
        RESULTS+=("Feature $i: PASSED")
    else
        RESULTS+=("Feature $i: FAILED")
    fi
    echo ""
done

# Summary
echo "========================================"
echo "SUMMARY"
echo "========================================"
for result in "${RESULTS[@]}"; do
    echo "$result"
done

