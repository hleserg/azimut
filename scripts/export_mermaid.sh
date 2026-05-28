#!/usr/bin/env bash
# Exports workspace.dsl to Mermaid diagram files in docs/diagrams/ (HLE-528).
# Output: structurizr-*.mmd files (one per view).
# Requires: Docker.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/docs/diagrams"

mkdir -p "$OUTPUT_DIR"

if ! docker info > /dev/null 2>&1; then
    echo "export-mermaid: Docker not available — skip" >&2
    exit 0
fi

echo "==> export-mermaid: exporting workspace.dsl → Mermaid..."
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$REPO_ROOT:/workspace" \
    structurizr/structurizr export \
    -w /workspace/workspace.dsl \
    -f mermaid \
    -o /workspace/docs/diagrams

echo "==> Generated diagrams in docs/diagrams/:"
for f in "$OUTPUT_DIR"/structurizr-*.mmd; do
    [ -f "$f" ] && echo "    $(basename "$f")"
done

# Stage generated .mmd files so they are included in the current commit
git -C "$REPO_ROOT" add "$OUTPUT_DIR"/structurizr-*.mmd 2>/dev/null || true

echo "==> Done."
