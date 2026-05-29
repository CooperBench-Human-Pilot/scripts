#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PATH="$SCRIPT_DIR/chi-task27_main"
COMBINED_PATCH="$SCRIPT_DIR/combined.patch"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_feature() {
    local feature_num=$1
    local test_patch="$SCRIPT_DIR/feature${feature_num}/tests.patch"
    
    echo "========================================"
    echo "Testing Feature $feature_num"
    echo "========================================"
    
    cd "$REPO_PATH"
    git reset --hard HEAD 2>/dev/null
    git clean -fdx 2>/dev/null
    
    if ! git apply --ignore-whitespace "$COMBINED_PATCH" 2>/dev/null; then
        echo -e "${RED}Failed to apply combined.patch${NC}"
        return 1
    fi
    
    if ! git apply --ignore-whitespace "$test_patch" 2>/dev/null; then
        echo -e "${RED}Failed to apply tests.patch for feature $feature_num${NC}"
        return 1
    fi
    
    TEST_FUNCS=$(grep -o "func Test[a-zA-Z0-9_]*" "$test_patch" 2>/dev/null | sed 's/func //' | sort -u | tr '\n' '|' | sed 's/|$//')
    
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

RESULTS=()
for i in 1 2 3 4; do
    if test_feature $i; then
        RESULTS+=("Feature $i: PASSED")
    else
        RESULTS+=("Feature $i: FAILED")
    fi
    echo ""
done

echo "========================================"
echo "SUMMARY"
echo "========================================"
for result in "${RESULTS[@]}"; do
    echo "$result"
done

