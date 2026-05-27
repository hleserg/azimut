# new-adr.ps1 <subfolder> <kebab-title>
# Creates a new ADR from template.md with the next sequential number.
# Scans ALL subdirs under docs/architecture/adr/ for the global max number.
#
# Usage:
#   .\scripts\new-adr.ps1 anti-hallucinations my-new-rule
#   .\scripts\new-adr.ps1 foundation use-deepseek-v5
param(
    [Parameter(Mandatory=$true)][string]$Subfolder,
    [Parameter(Mandatory=$true)][string]$Title
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AdrRoot  = Join-Path $RepoRoot 'docs/architecture/adr'
$Template = Join-Path $AdrRoot 'template.md'
$TargetDir = Join-Path $AdrRoot $Subfolder

if (-not (Test-Path $TargetDir -PathType Container)) {
    Write-Error "Subfolder not found: $TargetDir"
    exit 1
}
if (-not (Test-Path $Template -PathType Leaf)) {
    Write-Error "Template not found: $Template"
    exit 1
}

# Find global max ADR number across all subdirs
$Max = 0
Get-ChildItem -Path $AdrRoot -Recurse -Depth 1 -Filter '*.md' | ForEach-Object {
    if ($_.Name -match '^(\d{4})-') {
        $Num = [int]$Matches[1]
        if ($Num -gt $Max) { $Max = $Num }
    }
}

$Next       = $Max + 1
$NextPadded = '{0:D4}' -f $Next
$Date       = (Get-Date -Format 'yyyy-MM-dd')
$FileName   = "${NextPadded}-${Title}.md"
$Output     = Join-Path $TargetDir $FileName

if (Test-Path $Output) {
    Write-Error "File already exists: $Output"
    exit 1
}

$Content = Get-Content $Template -Raw -Encoding UTF8
$Content = $Content -replace 'YYYY-MM-DD', $Date
$Content = $Content -replace '\{Короткий заголовок, описывающий решение\}', $Title
$Content = $Content -replace '"proposed \| accepted \| rejected \| deprecated \| superseded by NNNN"', '"proposed"'

[System.IO.File]::WriteAllText($Output, $Content, [System.Text.Encoding]::UTF8)

Write-Host "Created: $Output"
Write-Host "Number:  $NextPadded"
Write-Host "Next after this will be: $('{0:D4}' -f ($Next + 1))"
