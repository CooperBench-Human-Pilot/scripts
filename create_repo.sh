#!/bin/bash

# Load from .env if present
if [ -f .env ]; then
  source .env
fi

ORG_NAME="CooperBench-Human-Pilot"
REPO_NAME="${1:?Usage: $0 <repo-name>}"
GITHUB_TOKEN="${GITHUB_TOKEN:?GITHUB_TOKEN is not set. Set it in .env or export it.}"

# Create repo in the org
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$ORG_NAME/repos \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"Created via API\",
    \"private\": false,
    \"auto_init\": false
  }" | jq '.html_url'