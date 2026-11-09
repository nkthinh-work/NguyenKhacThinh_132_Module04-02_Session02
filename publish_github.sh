#!/usr/bin/env sh
# Run from extracted repository after installing and authenticating GitHub CLI.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"
REPO_NAME='quickbite-docker-session-02'
VISIBILITY="${1:-private}"
case "$VISIBILITY" in private|public) ;; *) echo 'Usage: ./publish_github.sh [private|public]' >&2; exit 2;; esac
command -v git >/dev/null 2>&1 || { echo 'Please install git.' >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo 'Please install GitHub CLI (gh): https://cli.github.com/' >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo 'Run: gh auth login' >&2; exit 1; }
if [ ! -d .git ]; then
    git init
    git branch -M main
fi
git add .
if ! git diff --cached --quiet; then
    git commit -m 'Complete Docker PostgreSQL Session 02 exercises'
fi
if git remote get-url origin >/dev/null 2>&1; then
    git push -u origin main
else
    gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
fi
