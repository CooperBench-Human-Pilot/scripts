# Scripts

Utility scripts for managing repositories in the [CooperBench-Human-Pilot](https://github.com/CooperBench-Human-Pilot) GitHub org.

## create_repo.sh

Creates a new repository in the org and initializes a local git repo pointed at it.

### Prerequisites

- [`curl`](https://curl.se/)
- [`jq`](https://jqlang.org/)
- A GitHub Personal Access Token with `repo` and `admin:org` scopes

### Setup

```bash
cp .env.example .env
# Edit .env and set GITHUB_TOKEN to your personal access token
```

### Usage

```bash
chmod +x create_repo.sh
./create_repo.sh <repo-name>
```

Then push your files:

```bash
git add <files>
git commit -m "Initial commit"
git push -u origin main
```
