#!/bin/bash

set -e

# Load from .env if present
if [ -f .env ]; then
  source .env
fi

DRY_RUN=false
FORCE_REPUSH=false
DATASET="dataset/subsets/flash_15_dataset.json"
WORK_DIR="/tmp/cooperbench-repos"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force-repush) FORCE_REPUSH=true ;;
    --work-dir=*) WORK_DIR="${arg#--work-dir=}" ;;
    --dataset=*) DATASET="${arg#--dataset=}" ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

ORG_NAME="CooperBench-Human-Pilot"
if [ "$DRY_RUN" = false ]; then
  GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is not set. Set it in .env or export it.}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATASET_DIR="$SCRIPT_DIR/dataset"

mkdir -p "$WORK_DIR"

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] No GitHub API calls or git pushes will be made."
fi

# Create a GitHub repo in the org; no-op if it already exists
create_github_repo() {
  local repo_name="$1"
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] Would create GitHub repo: $ORG_NAME/$repo_name"
    return
  fi
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/orgs/$ORG_NAME/repos \
    -d "{
      \"name\": \"$repo_name\",
      \"description\": \"CooperBench task repository\",
      \"private\": false,
      \"auto_init\": false
    }")
  if [ "$response" = "201" ]; then
    echo "Created GitHub repo: $repo_name"
  elif [ "$response" = "422" ]; then
    echo "GitHub repo already exists: $repo_name"
  else
    echo "Warning: unexpected HTTP $response when creating $repo_name"
  fi
}

# Returns 0 if both feature branches already exist on the remote repo
pair_repo_complete() {
  local repo_name="$1" feat1="$2" feat2="$3"
  for branch in "feature${feat1}" "feature${feat2}"; do
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${ORG_NAME}/${repo_name}/branches/${branch}")
    [ "$status" != "200" ] && return 1
  done
  return 0
}


parse_setup_sh() {
  local setup_file="$1"
  # Strip inline comments and whitespace after the value
  PARSED_REPO_NAME=$(grep -E '^REPO_NAME=' "$setup_file" | head -1 | cut -d= -f2- | tr -d '"' | sed 's/[[:space:]]*#.*//' | xargs)
  PARSED_REPO_OWNER=$(grep -E '^REPO_OWNER=' "$setup_file" | head -1 | cut -d= -f2- | tr -d '"' | sed 's/[[:space:]]*#.*//' | xargs)
  PARSED_BASE_COMMIT=$(grep -E '^BASE_COMMIT=' "$setup_file" | head -1 | cut -d= -f2- | tr -d '"' | sed 's/[[:space:]]*#.*//' | xargs)
}

# Process every task in the dataset
process_dataset() {
  local dataset_file="$1"

  local num_tasks
  num_tasks=$(jq '.tasks | length' "$dataset_file")

  for i in $(seq 0 $((num_tasks - 1))); do
    local repo task_id
    repo=$(jq -r ".tasks[$i].repo" "$dataset_file")
    task_id=$(jq -r ".tasks[$i].task_id" "$dataset_file")

    local task_dir="$DATASET_DIR/$repo/task${task_id}"
    local setup_sh="$task_dir/setup.sh"

    if [ ! -f "$setup_sh" ]; then
      echo "ERROR: setup.sh not found at $setup_sh — skipping task $task_id"
      continue
    fi

    parse_setup_sh "$setup_sh"
    local source_repo_name="$PARSED_REPO_NAME"
    local base_commit="$PARSED_BASE_COMMIT"

    local clone_dir="$WORK_DIR/${repo}-task${task_id}"

    echo ""
    echo "=== Processing $repo / task$task_id (pairs: $(jq -r ".tasks[$i].pairs | length" "$dataset_file")) ==="
    echo "  Source repo : $source_repo_name"
    echo "  Base commit : $base_commit"

    # ----------------------------------------------------------------
    # 1. Clone the upstream source repo at the base commit
    # ----------------------------------------------------------------
    if [ ! -d "$clone_dir" ]; then
      echo "  Cloning upstream..."
      # Extract the clone URL from setup.sh (the git clone line)
      local clone_url
      clone_url=$(grep -E 'git clone ' "$setup_sh" | grep -v '^#' | head -1 | awk '{print $3}')
      # Substitute ${REPO_OWNER} and ${REPO_NAME} if the URL uses variables
      clone_url="${clone_url/\$\{REPO_OWNER\}/$PARSED_REPO_OWNER}"
      clone_url="${clone_url/\$\{REPO_NAME\}/$PARSED_REPO_NAME}"
      clone_url="${clone_url/\$REPO_OWNER/$PARSED_REPO_OWNER}"
      clone_url="${clone_url/\$REPO_NAME/$PARSED_REPO_NAME}"
      if [ -z "$clone_url" ]; then
        echo "  ERROR: could not extract clone URL from setup.sh — skipping"
        continue
      fi
      git -c credential.helper= clone "$clone_url" "$clone_dir"
    else
      echo "  Using existing clone at $clone_dir"
    fi

    # ----------------------------------------------------------------
    # 2. For each feature pair, create one GitHub repo with two branches
    # ----------------------------------------------------------------
    local num_pairs
    num_pairs=$(jq ".tasks[$i].pairs | length" "$dataset_file")

    for p in $(seq 0 $((num_pairs - 1))); do
      local feat1 feat2
      feat1=$(jq -r ".tasks[$i].pairs[$p][0]" "$dataset_file")
      feat2=$(jq -r ".tasks[$i].pairs[$p][1]" "$dataset_file")

      # One repo per pair: e.g. pillow_task-task68-f1-f5
      local pair_repo_name="${repo}-task${task_id}-f${feat1}-f${feat2}"

      echo "  Pair ($feat1, $feat2) → repo: $pair_repo_name"

      if [ "$DRY_RUN" = false ] && [ "$FORCE_REPUSH" = false ] && pair_repo_complete "$pair_repo_name" "$feat1" "$feat2"; then
        echo "  Skipping — already complete."
        continue
      fi

      git -C "$clone_dir" -c credential.helper= fetch origin --quiet

      # Export the tree at base commit into a fresh repo — no history
      local staging_dir="$WORK_DIR/staging-${pair_repo_name}"
      rm -rf "$staging_dir"
      mkdir -p "$staging_dir"
      git -C "$clone_dir" archive "$base_commit" | tar -x -C "$staging_dir"

      pushd "$staging_dir" > /dev/null

      git init --quiet
      git symbolic-ref HEAD refs/heads/main  # default branch: main
      git add -A
      git commit -m "Base at $base_commit" --quiet

      create_github_repo "$pair_repo_name"

      local remote_url="https://${GITHUB_TOKEN}@github.com/${ORG_NAME}/${pair_repo_name}.git"
      git remote add origin "$remote_url"

      echo "    Pushing base commit to main..."
      if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] Would push base commit to $pair_repo_name main"
      else
        git -c credential.helper= push origin "HEAD:refs/heads/main" --force --quiet
      fi

      for feat in "$feat1" "$feat2"; do
        local feature_dir="$task_dir/feature${feat}"
        local feature_md="$feature_dir/feature.md"
        local branch_name="feature${feat}"

        echo "    Creating branch: $branch_name"

        git checkout main --quiet
        git checkout -B "$branch_name" --quiet

        if [ -f "$feature_md" ]; then
          cp "$feature_md" task.md
          git add task.md
          git commit -m "Add task.md for feature $feat" --quiet
        else
          echo "    Warning: $feature_md not found — branch created without task.md"
        fi

        if [ "$DRY_RUN" = true ]; then
          echo "    [dry-run] Would push branch $branch_name to $pair_repo_name"
        else
          git -c credential.helper= push origin "$branch_name:refs/heads/$branch_name" --force --quiet
        fi
      done

      popd > /dev/null
      rm -rf "$staging_dir"

      if [ "$DRY_RUN" = true ]; then
        echo "    Done (dry run): would create https://github.com/${ORG_NAME}/${pair_repo_name}"
      else
        echo "    Done: https://github.com/${ORG_NAME}/${pair_repo_name}"
      fi
    done
  done
}

process_dataset "$SCRIPT_DIR/$DATASET"

echo ""
echo "All tasks processed."
