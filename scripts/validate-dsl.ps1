#Requires -Version 5.1
# Validates workspace.dsl:
#   1. Structurizr CLI syntax check (via Docker)
#   2. All "adr-link" properties point to existing files
# Exit code 0 = all checks passed; 1 = any check failed.
# NOTE: tested on Linux/WSL only; Docker Desktop for Windows users may need to
#       adjust the volume-mount path format if the drive letter is not accepted.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Push-Location $RepoRoot

try {
    $Failed = $false

    # ── 1. Structurizr CLI syntax validation ─────────────────────────────────
    Write-Host '==> Validating DSL syntax via Structurizr CLI...'
    docker run --rm `
        -v "${RepoRoot}:/usr/local/structurizr" `
        structurizr/cli validate `
        -workspace workspace.dsl
    if ($LASTEXITCODE -ne 0) {
        Write-Host '    FAIL: DSL syntax invalid.'
        $Failed = $true
    } else {
        Write-Host '    OK: DSL syntax valid.'
    }

    # ── 2. adr-link existence check ──────────────────────────────────────────
    Write-Host '==> Checking adr-link references in workspace.dsl...'
    $AdrErrors = 0

    foreach ($line in (Get-Content 'workspace.dsl')) {
        if ($line -match '"adr-link"\s+"([^"]+)"') {
            $linkPath = $Matches[1]
            $fullPath = Join-Path $RepoRoot $linkPath
            if (-not (Test-Path $fullPath -PathType Leaf)) {
                Write-Host "    FAIL: adr-link not found: $linkPath"
                $AdrErrors++
            }
        }
    }

    if ($AdrErrors -eq 0) {
        Write-Host '    OK: all adr-link references resolved.'
    } else {
        Write-Host "    FAIL: $AdrErrors missing adr-link reference(s)."
        $Failed = $true
    }

    # ── Result ────────────────────────────────────────────────────────────────
    Write-Host ''
    if ($Failed) {
        Write-Host 'Validation FAILED.'
        exit 1
    }
    Write-Host 'Validation passed.'
} finally {
    Pop-Location
}
