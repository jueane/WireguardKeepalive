#!/bin/bash

set -euo pipefail

REPO_OWNER="jueane"
REPO_NAME="WireguardKeepalive"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: missing command: $1" >&2
        exit 1
    fi
}

require_cmd curl
require_cmd git

upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
if [ -z "$upstream" ]; then
    echo "Error: current branch has no upstream. Push the branch or set upstream before releasing." >&2
    exit 1
fi

git fetch --tags origin

unpushed_count="$(git rev-list --count "${upstream}..HEAD")"
if [ "$unpushed_count" -ne 0 ]; then
    echo "Error: local HEAD has $unpushed_count unpushed commit(s). Push them before releasing." >&2
    exit 1
fi

echo "Fetching latest release from GitHub..."
latest_version="$(
    curl -fsSL "$GITHUB_API" |
        grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' |
        head -n 1 |
        sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
)"

if [ -z "$latest_version" ]; then
    echo "Error: failed to parse latest release version." >&2
    exit 1
fi

if [[ ! "$latest_version" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Error: unsupported version format: $latest_version" >&2
    echo "Expected format: vMAJOR.MINOR.PATCH, for example v0.1.19" >&2
    exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"
next_version="v${major}.${minor}.$((patch + 1))"

echo "Latest release: $latest_version"
echo "Next release:   $next_version"

if git rev-parse -q --verify "refs/tags/${next_version}" >/dev/null; then
    echo "Error: tag already exists locally: $next_version" >&2
    exit 1
fi

git tag "$next_version"
git push origin "$next_version"

echo "Pushed release tag: $next_version"
