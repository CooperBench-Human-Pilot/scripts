#!/bin/bash

# Test selected features for task1706
# Usage: ./test_features.sh [feature_numbers...]
# Examples:
#   ./test_features.sh 1 2 3     # Test features 1, 2, 3
#   ./test_features.sh all       # Test all features

TASK_DIR="/Users/arpan/Desktop/CodeConflictBenchmark/dataset/dottxt_ai_outlines_task/task1706"
REPO_DIR="$TASK_DIR/outlines-pr-1706"
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
        1) echo "TestXGrammarLogitsProcessor or TestXGrammarBackend or TestXGrammarIntegration" ;;
        2) echo "caching" ;;
        3) echo "temperature" ;;
        4) echo "batch" ;;
        5) echo "custom_adapter or tensor_library" ;;
        6) echo "validate_grammar" ;;
        7) echo "fallback" ;;
        8) echo "memory" ;;
        *) echo "" ;;
    esac
}

get_feature_name() {
    case $1 in
        1) echo "Custom Logits Processor with MLX Support" ;;
        2) echo "Grammar Caching System" ;;
        3) echo "Temperature Parameter" ;;
        4) echo "Batch Size Validation" ;;
        5) echo "Custom Tensor Library Support" ;;
        6) echo "Grammar Validation Hook" ;;
        7) echo "Fallback Processor Chain" ;;
        8) echo "Memory Usage Monitoring" ;;
        *) echo "Unknown" ;;
    esac
}

# Parse arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 [feature_numbers...] or 'all'"
    echo ""
    echo "Features:"
    echo "  1  - Custom Logits Processor with MLX Support"
    echo "  2  - Grammar Caching System"
    echo "  3  - Temperature Parameter"
    echo "  4  - Batch Size Validation"
    echo "  5  - Custom Tensor Library Support"
    echo "  6  - Grammar Validation Hook"
    echo "  7  - Fallback Processor Chain"
    echo "  8  - Memory Usage Monitoring"
    exit 0
elif [ "$1" == "all" ]; then
    FEATURES=(1 2 3 4 5 6 7 8)
else
    FEATURES=("$@")
fi

# Test a single feature
test_feature() {
    local feature_num=$1
    local test_patch="$TASK_DIR/feature$feature_num/tests.patch"
    local pattern=$(get_test_pattern "$feature_num")
    local name=$(get_feature_name "$feature_num")
    
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Testing Feature $feature_num: $name${NC}"
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

    # Set environment variables to avoid unnecessary dependencies
    export TRANSFORMERS_NO_TF=1
    export TRANSFORMERS_NO_FLAX=1
    export PANDAS_NO_USE_PYARROW=1
    export LLAMA_CPP_FORCE_CPU=1
    export PYTORCH_ENABLE_MPS_FALLBACK=1

    uv pip install -e . -q 2>/dev/null
    uv pip install pytest pytest_mock torch transformers sentencepiece xgrammar llama-cpp-python==0.3.16 psutil -q 2>/dev/null
    
    # Run tests using a Python wrapper to avoid segfault on shutdown
    echo "Running tests with pattern: $pattern"
    if [ -n "$pattern" ]; then
        .venv/bin/python - <<PY
import os, sys, pytest
code = pytest.main(["tests/backends/test_xgrammar.py", "-v", "-k", "$pattern"])
if code == 0:
    os._exit(0)
sys.exit(code)
PY
    else
        .venv/bin/python - <<PY
import os, sys, pytest
code = pytest.main(["tests/backends/test_xgrammar.py", "-v"])
if code == 0:
    os._exit(0)
sys.exit(code)
PY
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

