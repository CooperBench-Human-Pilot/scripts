#!/bin/bash

# Test all features for task56
# This script tests each feature individually after applying the combined patch

TASK_DIR="/Users/arpan/Desktop/CodeConflictBenchmark/dataset/go_chi_task/task56"
REPO_DIR="$TASK_DIR/chi-task56_main"
COMBINED_PATCH="$TASK_DIR/combined.patch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test a single feature
test_feature() {
    local feature_num=$1
    local feature_dir="$TASK_DIR/feature$feature_num"
    local test_patch="$feature_dir/tests.patch"
    
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Testing Feature $feature_num${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    # Reset to clean state
    cd "$REPO_DIR"
    git reset --hard HEAD
    git clean -fdx
    
    # Apply combined patch
    echo "Applying combined patch..."
    git apply --3way "$COMBINED_PATCH"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to apply combined patch${NC}"
        return 1
    fi
    
    # Apply test patch if it exists
    if [ -f "$test_patch" ]; then
        echo "Applying test patch for feature $feature_num..."
        git apply --3way "$test_patch"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to apply test patch for feature $feature_num${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}No test patch found for feature $feature_num${NC}"
        return 0
    fi
    
    # Run the tests
    echo "Running tests for feature $feature_num..."
    
    case $feature_num in
        1)
            go test -v -run "TestMethodNotAllowedWithAllowHeader" ./...
            ;;
        2)
            go test -v -run "TestInvalidMethod" ./...
            ;;
        3)
            go test -v -run "TestRouteTracing" ./...
            ;;
        4)
            go test -v -run "TestMethodValidator" ./...
            ;;
        5)
            go test -v -run "TestCORS" ./...
            ;;
        *)
            go test -v ./...
            ;;
    esac
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}Feature $feature_num: PASSED${NC}"
    else
        echo -e "${RED}Feature $feature_num: FAILED${NC}"
    fi
    
    return $result
}

# Main execution
echo "Starting tests for all features..."
echo ""

FAILED_FEATURES=()
PASSED_FEATURES=()

for i in 1 2 3 4 5; do
    if [ -d "$TASK_DIR/feature$i" ]; then
        test_feature $i
        if [ $? -eq 0 ]; then
            PASSED_FEATURES+=($i)
        else
            FAILED_FEATURES+=($i)
        fi
        echo ""
    fi
done

# Summary
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Passed: ${PASSED_FEATURES[*]:-none}${NC}"
echo -e "${RED}Failed: ${FAILED_FEATURES[*]:-none}${NC}"

# Final cleanup - reset repo
cd "$REPO_DIR"
git reset --hard HEAD
git clean -fdx

if [ ${#FAILED_FEATURES[@]} -eq 0 ]; then
    echo -e "${GREEN}All features passed!${NC}"
    exit 0
else
    echo -e "${RED}Some features failed.${NC}"
    exit 1
fi
