#!/usr/bin/env bash
set -euo pipefail

OUTPUT=${1:-conflict_pairs.csv}
BASE_COMMIT=4560a8896f5fb1d35c6f8fd6eee0399f9a1a27ca
FEATURES=(1 2 3 4 5 6 7 8 9 10)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_DIR="$SCRIPT_DIR/task0"
REPO_DIR="$TASK_DIR/tiktoken-pr-0_main"

cd "$REPO_DIR"

git checkout --quiet "$BASE_COMMIT"
git clean -fd >/dev/null

for f in "${FEATURES[@]}"; do
  git branch -D "feat_$f" >/dev/null 2>&1 || true
  git checkout --quiet -b "feat_$f" "$BASE_COMMIT"
  git clean -fd >/dev/null
  git apply "$TASK_DIR/feature${f}/feature.patch"
  if [[ -f "$TASK_DIR/feature${f}/tests.patch" ]]; then
    git apply "$TASK_DIR/feature${f}/tests.patch"
  fi
  git add -A
  git commit -qm "feature$f"
  git checkout --quiet "$BASE_COMMIT"
  git clean -fd >/dev/null
done

results=()
for ((i=0; i<${#FEATURES[@]}; ++i)); do
  fi=${FEATURES[i]}
  for ((j=i+1; j<${#FEATURES[@]}; ++j)); do
    fj=${FEATURES[j]}
    git checkout --quiet "feat_$fj"
    git reset --hard HEAD >/dev/null
    git clean -fd >/dev/null
    if git merge -q "feat_$fi" --no-commit --no-ff; then
      status="clean"
      git reset --hard HEAD >/dev/null
    else
      status="conflict"
      git merge --abort >/dev/null 2>&1 || true
    fi
    results+=("${fi},${fj},${status}")
  done
done

printf "%s\n" "${results[@]}" > "$TASK_DIR/${OUTPUT}"
echo "Wrote ${#results[@]} pairs to $TASK_DIR/${OUTPUT}" >&2
