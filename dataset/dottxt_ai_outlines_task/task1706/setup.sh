#!/bin/bash
# Setup script for Task {number}: PR #{number} - Only change readonly if saved filename matches opened filename

REPO_NAME="outlines-pr-1706"
BASE_COMMIT="947c904608821ef6e33493181f87653e25b08862"

# Create a directory for the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning repository..."
    git clone https://github.com/dottxt-ai/outlines "$REPO_NAME"
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
git branch -D "outlines_task1706" 2>/dev/null
git checkout -b "outlines_task1706"

git restore .
git restore --staged .


## GENERATE VENV
export TRANSFORMERS_NO_TF=1
export TRANSFORMERS_NO_FLAX=1
export PANDAS_NO_USE_PYARROW=1
export LLAMA_CPP_FORCE_CPU=1          # disables Metal path in llama-cpp-python
export PYTORCH_ENABLE_MPS_FALLBACK=1  # harmless; avoids MPS surprises

uv venv
source .venv/bin/activate

uv sync
uv pip install -e .
uv pip install pytest pytest-xdist pytest_mock
uv pip install \
  pytest pytest-asyncio pytest-benchmark pytest-cov pytest-mock \
  torch transformers sentencepiece xgrammar llama-cpp-python==0.3.16

if [ -f "uv.lock" ]; then
    echo "Installing dependencies from uv.lock..."
    uv sync --active
    # Install the package in editable mode with test dependencies
    echo "Installing test dependencies..."
    if uv pip install -e ".[test]" 2>/dev/null; then
        echo "Test dependencies installed successfully"
    else
        echo "Test dependencies not available, installing basic package and fallback test tools"
        uv pip install -e .
        uv pip install pytest pytest-xdist pytest_mock
    fi
else
    # Install with test dependencies if available, fallback to basic install
    if uv pip install -e ".[test]" 2>/dev/null; then
        echo "Test dependencies installed successfully"
    else
        echo "Test dependencies not available, installing basic package and fallback test tools"
        uv pip install -e .
        uv pip install pytest pytest-xdist pytest_mock
    fi
fi
