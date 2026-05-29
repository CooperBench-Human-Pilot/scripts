#!/bin/bash

set -e

# Cleanup function
test_cleanup() {
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        git reset --hard HEAD 2>/dev/null || true
        git clean -fdx 2>/dev/null || true
    fi
}
trap test_cleanup EXIT INT TERM

usage() {
    echo "Usage: $0 <repo_path> <test_patch> [feature_patch]"
    exit 1
}

REPO_PATH="$1"
TEST_PATCH="$2"
FEATURE_PATCH="$3"

[[ -z "$REPO_PATH" || -z "$TEST_PATCH" ]] && usage
[[ ! -d "$REPO_PATH" ]] && { echo "Repository not found at $REPO_PATH"; exit 1; }
[[ ! -f "$TEST_PATCH" ]] && { echo "Test patch not found at $TEST_PATCH"; exit 1; }
[[ -n "$FEATURE_PATCH" && ! -f "$FEATURE_PATCH" ]] && { echo "Feature patch not found at $FEATURE_PATCH"; exit 1; }

TEST_PATCH="$(realpath "$TEST_PATCH")"
[[ -n "$FEATURE_PATCH" ]] && FEATURE_PATCH="$(realpath "$FEATURE_PATCH")"

cd "$REPO_PATH"

# Apply feature patch if provided
if [[ -n "$FEATURE_PATCH" ]]; then
    git apply --ignore-whitespace --ignore-space-change "$FEATURE_PATCH" || git apply --3way "$FEATURE_PATCH"
fi

git apply --ignore-whitespace --ignore-space-change "$TEST_PATCH" || git apply --3way "$TEST_PATCH"

# Ensure Go is installed
if ! command -v go >/dev/null 2>&1; then
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    GO_VERSION="1.24.2"
    if [ "$OS" == "darwin" ] || [ "$OS" == "linux" ]; then
        GO_URL="https://go.dev/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    else
        echo "Unsupported operating system: $OS"; exit 1
    fi
    TMP_DIR=$(mktemp -d)
    GO_TARBALL="${TMP_DIR}/go.tar.gz"
    if command -v curl &> /dev/null; then
        curl -sSL "$GO_URL" -o "$GO_TARBALL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$GO_TARBALL" "$GO_URL"
    else
        echo "Neither curl nor wget found. Please install one of them."; exit 1
    fi
    if [ -w "/usr/local" ]; then
        tar -C /usr/local -xzf "$GO_TARBALL"
    else
        if command -v sudo &> /dev/null; then
            sudo tar -C /usr/local -xzf "$GO_TARBALL"
        else
            echo "Cannot write to /usr/local and sudo not available."; exit 1
        fi
    fi
    export PATH=$PATH:/usr/local/go/bin
    rm -rf "$TMP_DIR"
fi

go version

echo "Analyzing test patch for test functions..."
TEST_FUNCS=()
NEW_FUNCS=$(grep -o "func Test[a-zA-Z0-9_]*" "$TEST_PATCH" 2>/dev/null | sed 's/func //' || true)
for func in $NEW_FUNCS; do
    TEST_FUNCS+=("$func")
done

TEST_PATTERN=""
if [ ${#TEST_FUNCS[@]} -gt 0 ]; then
    TEST_PATTERN=$(IFS="|"; echo "${TEST_FUNCS[*]}" | sort -u)
    echo "Found test functions to run: $TEST_PATTERN"
fi

echo "Running Go tests..."
if [ -n "$TEST_PATTERN" ]; then
    go test -run "$TEST_PATTERN" ./...
    TEST_EXIT_CODE=$?
else
    go test ./...
    TEST_EXIT_CODE=$?
fi

echo "Test run completed!"
exit $TEST_EXIT_CODE