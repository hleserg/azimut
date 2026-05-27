#!/usr/bin/env bash
# new-adr.sh <subfolder> <kebab-title>
# Creates a new ADR from template.md with the next sequential number.
# Scans ALL subdirs under docs/architecture/adr/ for the global max number.
#
# Usage:
#   ./scripts/new-adr.sh anti-hallucinations my-new-rule
#   ./scripts/new-adr.sh foundation use-deepseek-v5
set -euo pipefail

SUBFOLDER="${1:-}"
TITLE="${2:-}"

if [[ -z "$SUBFOLDER" || -z "$TITLE" ]]; then
  echo "Usage: $0 <subfolder> <kebab-title>" >&2
  echo "Subfolders: anti-hallucinations, foundation, code-processing, tooling, open" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADR_ROOT="$REPO_ROOT/docs/architecture/adr"
TEMPLATE="$ADR_ROOT/template.md"
TARGET_DIR="$ADR_ROOT/$SUBFOLDER"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: subfolder '$TARGET_DIR' does not exist." >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: template not found at '$TEMPLATE'." >&2
  exit 1
fi

# Find global max ADR number across all subdirs (pattern: NNNN-*.md)
MAX=0
while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  if [[ "$filename" =~ ^([0-9]{4})- ]]; then
    NUM="${BASH_REMATCH[1]}"
    NUM_DEC=$((10#$NUM))
    if (( NUM_DEC > MAX )); then
      MAX=$NUM_DEC
    fi
    fi
  fi
done < <(find "$ADR_ROOT" -mindepth 2 -maxdepth 2 -name "[0-9][0-9][0-9][0-9]-*.md" -print0)

NEXT=$(( MAX + 1 ))
NEXT_PADDED="$(printf '%04d' "$NEXT")"
DATE="$(date +%Y-%m-%d)"
FILENAME="${NEXT_PADDED}-${TITLE}.md"
OUTPUT="$TARGET_DIR/$FILENAME"

if [[ -f "$OUTPUT" ]]; then
  echo "Error: '$OUTPUT' already exists." >&2
  exit 1
fi

# Copy template and substitute placeholders (write to temp first to avoid empty file on failure)
TMPOUT="$(mktemp)"
sed \
  -e "s|YYYY-MM-DD|$DATE|g" \
  -e "s|{Короткий заголовок, описывающий решение}|$TITLE|g" \
  -e 's/"proposed | accepted | rejected | deprecated | superseded by NNNN"/"proposed"/' \
  "$TEMPLATE" > "$TMPOUT"
mv "$TMPOUT" "$OUTPUT"

echo "Created: $OUTPUT"
echo "Number:  $NEXT_PADDED"
echo "Next after this will be: $(printf '%04d' $(( NEXT + 1 )))"
