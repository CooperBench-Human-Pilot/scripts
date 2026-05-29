#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Default values
REPO_PATH=""
TEST_PATCH=""
FEATURE_PATCH=""
UNIT_TEST_SPEC="tests/adapters/test_tool.py tests/adapters/test_chat_adapter.py"

DSPY_CACHEDIR="$REPO_PATH/.dspy_cache"

# Parse command line arguments (support both flags and positional args)
# Accepted forms:
#   ./run_tests.sh --repo-path <dir> --test-patch <patch> [--feature-patch <patch>] [--test-spec <pytest_path>]
#   ./run_tests.sh <dir> <test_patch> [feature_patch] [pytest_path]
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo-path)
            REPO_PATH="$2"; shift 2 ;;
        --test-patch)
            TEST_PATCH="$2"; shift 2 ;;
        --feature-patch)
            FEATURE_PATCH="$2"; shift 2 ;;
        --test-spec)
            UNIT_TEST_SPEC="$2"; shift 2 ;;
        --)
            shift; break ;;
        -*)
            echo "Unknown option: $1"; exit 1 ;;
        *)
            POSITIONAL_ARGS+=("$1"); shift ;;
    esac
done

# Fallback to positional parsing if flags not used
if [[ -z "$REPO_PATH" && ${#POSITIONAL_ARGS[@]} -ge 1 ]]; then
    REPO_PATH="${POSITIONAL_ARGS[0]}"
fi
if [[ -z "$TEST_PATCH" && ${#POSITIONAL_ARGS[@]} -ge 2 ]]; then
    TEST_PATCH="${POSITIONAL_ARGS[1]}"
fi
if [[ -z "$FEATURE_PATCH" && ${#POSITIONAL_ARGS[@]} -ge 3 ]]; then
    FEATURE_PATCH="${POSITIONAL_ARGS[2]}"
fi
# Allow overriding UNIT_TEST_SPEC via 4th positional arg (optional)
if [[ ${#POSITIONAL_ARGS[@]} -ge 4 ]]; then
    UNIT_TEST_SPEC="${POSITIONAL_ARGS[3]}"
fi

# Verify required arguments
if [ -z "$REPO_PATH" ]; then
    echo "Error: Repository path not provided. Use --repo-path flag or positional arg."
    exit 1
fi

if [ -z "$TEST_PATCH" ]; then
    echo "Error: Test patch not provided. Use --test-patch flag or positional arg."
    exit 1
fi

# Convert paths to absolute paths
REPO_PATH=$(realpath "$REPO_PATH")
TEST_PATCH=$(realpath "$TEST_PATCH")
if [ -n "$FEATURE_PATCH" ]; then
    FEATURE_PATCH=$(realpath "$FEATURE_PATCH")
fi

# Verify repository directory exists
if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Repository directory not found at $REPO_PATH"
    exit 1
fi

# Verify patch file(s) exist
if [ ! -f "$TEST_PATCH" ]; then
    echo "Error: Test patch file not found at $TEST_PATCH"
    exit 1
fi
if [ -n "$FEATURE_PATCH" ] && [ ! -f "$FEATURE_PATCH" ]; then
    echo "Error: Feature patch file not found at $FEATURE_PATCH"
    exit 1
fi

# Run the test
echo "Running tests with:"
echo "Repository: $REPO_PATH"
echo "Test patch: $TEST_PATCH"

cd "$REPO_PATH"

# --- Cleanup Function ---
# Ensures only the target repository is reset and cleaned after tests complete.
cleanup() {
    echo "Cleaning up repository..."
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        CURRENT_BRANCH_OR_COMMIT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        echo "Resetting to HEAD ($CURRENT_BRANCH_OR_COMMIT) and cleaning..."
        git reset --hard HEAD || true
        git clean -fdx || true
        echo "Repository cleaned."
    else
        echo "Not inside a git repository at $REPO_PATH, skipping git cleanup."
    fi
}
trap cleanup EXIT INT TERM

# Ensure we start with a clean state
echo "Ensuring clean repository state..."
git reset --hard HEAD
git clean -fdx

# Apply test patch with better error handling
echo "Applying test patch..."
if ! git apply --check "$TEST_PATCH" 2>/dev/null; then
    echo "Warning: Patch check failed. Attempting to apply anyway..."
fi

if ! git apply "$TEST_PATCH"; then
    echo "Error: Failed to apply test patch. Repository state may not match expected base commit."
    echo "Patch file: $TEST_PATCH"
    exit 1
fi

echo "Test patch applied successfully."

# Optionally apply feature patch
if [ -n "$FEATURE_PATCH" ]; then
    echo "Applying feature patch..."
    if ! git apply --check "$FEATURE_PATCH" 2>/dev/null; then
        echo "Warning: Feature patch check failed. Attempting to apply anyway..."
    fi
    if ! git apply "$FEATURE_PATCH"; then
        echo "Error: Failed to apply feature patch."
        echo "Patch file: $FEATURE_PATCH"
        exit 1
    fi
    echo "Feature patch applied successfully."
fi

# Set up virtual environment with specific Python version
echo "Creating virtual environment..."
# Try to use Python 3.10+ if available, fallback to system Python
PYTHON_CMD="python3.10"
if ! command -v "$PYTHON_CMD" &> /dev/null; then
    PYTHON_CMD="python3.11"
fi
if ! command -v "$PYTHON_CMD" &> /dev/null; then
    PYTHON_CMD="python3.12"
fi
if ! command -v "$PYTHON_CMD" &> /dev/null; then
    echo "Warning: No Python 3.10+ found, using system Python. This may cause compatibility issues."
    PYTHON_CMD="python"
fi

echo "Using Python: $PYTHON_CMD"
"$PYTHON_CMD" -m venv .venv

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip and install the package in editable mode with dev dependencies
echo "Installing package in editable mode with dev dependencies..."
pip install --upgrade pip
pip install -e ".[dev]"

# Run tests
echo "Running tests..."
# Split UNIT_TEST_SPEC into separate arguments for pytest
IFS=' ' read -ra TEST_FILES <<< "$UNIT_TEST_SPEC"
python -m pytest "${TEST_FILES[@]}" -v

echo "Test execution completed!"

# Note: cleanup function will run automatically via trap
