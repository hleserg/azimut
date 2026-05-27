#!/usr/bin/env bash
# update-adr-index.sh
# Parses frontmatter of all ADR files and rebuilds the index table
# in docs/architecture/09-architectural-decisions.md between markers:
#   <!-- ADR-INDEX:START -->
#   <!-- ADR-INDEX:END -->
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADR_ROOT="$REPO_ROOT/docs/architecture/adr"
INDEX_FILE="$REPO_ROOT/docs/architecture/09-architectural-decisions.md"
START_MARKER="<!-- ADR-INDEX:START -->"
END_MARKER="<!-- ADR-INDEX:END -->"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Error: index file not found: $INDEX_FILE" >&2
  exit 1
fi

# Collect ADR data: number, subfolder, status, title (from H1)
# Output: NNNN|subfolder|status|title
declare -a ROWS=()

while IFS= read -r -d '' file; do
  filename="$(basename "$file")"
  subfolder="$(basename "$(dirname "$file")")"

  # Skip non-numbered files
  if [[ ! "$filename" =~ ^([0-9]{4})- ]]; then
    continue
  fi
  NUM="${BASH_REMATCH[1]}"

  # Extract frontmatter fields (between first pair of ---)
  status=""
  title=""
  in_frontmatter=0
  found_first=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if (( found_first == 0 )); then
        found_first=1
        in_frontmatter=1
        continue
      else
        break
      fi
    fi
    if (( in_frontmatter )); then
      if [[ "$line" =~ ^status:[[:space:]]*\"?([^\"]+)\"?$ ]]; then
        status="${BASH_REMATCH[1]}"
        status="${status%\"}"  # trim trailing quote if any
      fi
    fi
  done < "$file"

  # Extract H1 title (first line starting with "# ")
  while IFS= read -r line; do
    if [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
      title="${BASH_REMATCH[1]}"
      break
    fi
  done < "$file"

  [[ -z "$status" ]] && status="unknown"
  [[ -z "$title" ]] && title="$(echo "$filename" | sed 's/^[0-9]*-//;s/-/ /g')"

  ROWS+=("${NUM}|${subfolder}|${status}|${title}|${filename}")
done < <(find "$ADR_ROOT" -mindepth 2 -maxdepth 2 -name "[0-9][0-9][0-9][0-9]-*.md" -print0 | sort -z)

# Build markdown table
TABLE=""
TABLE+="| № | Тема | Статус | Заголовок |\n"
TABLE+="|---|---|---|---|\n"

for row in "${ROWS[@]}"; do
  IFS='|' read -r num subfolder status title filename <<< "$row"
  rel_path="adr/${subfolder}/${filename}"
  TABLE+="| ${num} | ${subfolder} | ${status} | [${title}](${rel_path}) |\n"
done

# Replace content between markers in index file
TMPFILE="$(mktemp)"
in_block=0
while IFS= read -r line; do
  if [[ "$line" == "$START_MARKER" ]]; then
    printf '%s\n' "$line" >> "$TMPFILE"
    printf '%b' "$TABLE" >> "$TMPFILE"
    in_block=1
    continue
  fi
  if [[ "$line" == "$END_MARKER" ]]; then
    in_block=0
  fi
  if (( in_block == 0 )); then
    printf '%s\n' "$line" >> "$TMPFILE"
  fi
done < "$INDEX_FILE"

mv "$TMPFILE" "$INDEX_FILE"
echo "Updated: $INDEX_FILE (${#ROWS[@]} ADR entries)"
