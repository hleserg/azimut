#!/usr/bin/env bash
# Validates workspace.dsl:
#   1. Structurizr CLI syntax check (via Docker)
#   2. All "adr-link" properties point to existing files
# Exit code 0 = all checks passed; 1 = any check failed.
# Requires: bash 4+ (mapfile), Docker
set -euo pipefail

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "ERROR: bash 4+ required (found ${BASH_VERSION}). On macOS: brew install bash" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FAILED=0

# ── 1. Structurizr CLI syntax validation ─────────────────────────────────────
echo "==> Validating DSL syntax via Structurizr CLI..."
if docker run --rm \
    -v "$REPO_ROOT:/usr/local/structurizr" \
    structurizr/cli validate \
    -workspace workspace.dsl; then
    echo "    OK: DSL syntax valid."
else
    echo "    FAIL: DSL syntax invalid."
    FAILED=1
fi

# ── 2. adr-link existence check ───────────────────────────────────────────────
echo "==> Checking adr-link references in workspace.dsl..."
ADR_ERRORS=0

mapfile -t ADR_PATHS < <(
    grep '"adr-link"' workspace.dsl \
        | sed -n 's/.*"adr-link"[[:space:]]*"\([^"]*\)".*/\1/p' \
        || true
)

for link_path in "${ADR_PATHS[@]+"${ADR_PATHS[@]}"}"; do
    if [ ! -f "$REPO_ROOT/$link_path" ]; then
        echo "    FAIL: adr-link not found: $link_path"
        ADR_ERRORS=$((ADR_ERRORS + 1))
    fi
done

if [ "$ADR_ERRORS" -eq 0 ]; then
    echo "    OK: all ${#ADR_PATHS[@]} adr-link(s) resolved."
else
    echo "    FAIL: $ADR_ERRORS missing adr-link reference(s)."
    FAILED=1
fi

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [ "$FAILED" -ne 0 ]; then
    echo "Validation FAILED."
    exit 1
fi
echo "Validation passed."
