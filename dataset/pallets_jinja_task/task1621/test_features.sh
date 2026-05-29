#!/bin/bash

# Test selected features for task1621
# Usage: ./test_features.sh [feature_numbers...]
# Examples:
#   ./test_features.sh 1 2 3     # Test features 1, 2, 3
#   ./test_features.sh all       # Test all features

TASK_DIR="/Users/arpan/Desktop/CodeConflictBenchmark/dataset/pallets_jinja_task/task1621"
REPO_DIR="$TASK_DIR/jinja-pr-1621"
COMBINED_PATCH="$TASK_DIR/combined.patch"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test patterns for each feature
get_test_pattern() {
    case $1 in
        1) echo "fallback" ;;
        2) echo "normalization" ;;
        3) echo "validation" ;;
        4) echo "priority" ;;
        5) echo "caching" ;;
        6) echo "transform" ;;
        7) echo "expansion" ;;
        8) echo "filter" ;;
        9) echo "monitoring or auto_reload" ;;
        10) echo "alias" ;;
        *) echo "" ;;
    esac
}

# Parse arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 [feature_numbers...] or 'all'"
    echo ""
    echo "Features:"
    echo "  1  - Fallback searchpath"
    echo "  2  - Path normalization"
    echo "  3  - Path validation"
    echo "  4  - Priority configuration"
    echo "  5  - Path caching"
    echo "  6  - Path transformation"
    echo "  7  - Path expansion"
    echo "  8  - Path filtering"
    echo "  9  - Auto-reload monitoring"
    echo "  10 - Path aliasing"
    exit 0
elif [ "$1" == "all" ]; then
    FEATURES=(1 2 3 4 5 6 7 8 9 10)
else
    FEATURES=("$@")
fi

# Test a single feature
test_feature() {
    local feature_num=$1
    local test_patch="$TASK_DIR/feature$feature_num/tests.patch"
    local pattern=$(get_test_pattern "$feature_num")
    
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Testing Feature $feature_num${NC}"
    echo -e "${YELLOW}========================================${NC}"
    
    # Reset repo
    cd "$REPO_DIR"
    git reset --hard HEAD >/dev/null 2>&1
    git clean -fdx >/dev/null 2>&1
    
    # Apply combined patch
    if [ -f "$COMBINED_PATCH" ]; then
        echo "Applying combined patch..."
        git apply --3way "$COMBINED_PATCH" 2>/dev/null || git apply "$COMBINED_PATCH" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to apply combined patch${NC}"
            return 1
        fi
    else
        echo -e "${RED}Combined patch not found: $COMBINED_PATCH${NC}"
        return 1
    fi
    
    # Apply test patch
    if [ -f "$test_patch" ]; then
        echo "Applying test patch for feature $feature_num..."
        git apply --3way "$test_patch" 2>/dev/null || git apply "$test_patch" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to apply test patch${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}No test patch found for feature $feature_num${NC}"
        return 0
    fi
    
    # Setup environment (only first time)
    if [ ! -d ".venv" ]; then
        echo "Setting up Python environment..."
        uv venv --python 3.11 >/dev/null 2>&1
    fi
    source .venv/bin/activate
    uv pip install -e . -q 2>/dev/null
    uv pip install pytest -q 2>/dev/null
    
    # Run tests
    echo "Running tests with pattern: $pattern"
    if [ -n "$pattern" ]; then
        python -m pytest tests/test_loader.py -v -k "$pattern" 2>&1
    else
        python -m pytest tests/test_loader.py -v 2>&1
    fi
    
    return $?
}

# Main execution
echo -e "${BLUE}Testing features: ${FEATURES[*]}${NC}"
echo ""

PASSED=()
FAILED=()

for feature_num in "${FEATURES[@]}"; do
    if [ -d "$TASK_DIR/feature$feature_num" ]; then
        test_feature "$feature_num"
        if [ $? -eq 0 ]; then
            PASSED+=("$feature_num")
        else
            FAILED+=("$feature_num")
        fi
        echo ""
    else
        echo -e "${RED}Feature $feature_num directory not found${NC}"
        FAILED+=("$feature_num")
    fi
done

# Final cleanup
cd "$REPO_DIR"
git reset --hard HEAD >/dev/null 2>&1
git clean -fdx >/dev/null 2>&1

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: ${PASSED[*]:-none}${NC}"
echo -e "${RED}Failed: ${FAILED[*]:-none}${NC}"

if [ ${#FAILED[@]} -eq 0 ]; then
    echo -e "${GREEN}All features passed!${NC}"
    exit 0
else
    echo -e "${RED}Some features failed.${NC}"
    exit 1
fi
