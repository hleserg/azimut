# update-adr-index.ps1
# Parses frontmatter of all ADR files and rebuilds the index table
# in docs/architecture/09-architectural-decisions.md between markers:
#   <!-- ADR-INDEX:START -->
#   <!-- ADR-INDEX:END -->
param()

$ErrorActionPreference = 'Stop'

$RepoRoot    = Split-Path -Parent $PSScriptRoot
$AdrRoot     = Join-Path $RepoRoot 'docs/architecture/adr'
$IndexFile   = Join-Path $RepoRoot 'docs/architecture/09-architectural-decisions.md'
$StartMarker = '<!-- ADR-INDEX:START -->'
$EndMarker   = '<!-- ADR-INDEX:END -->'

if (-not (Test-Path $IndexFile)) {
    Write-Error "Index file not found: $IndexFile"
    exit 1
}

# Collect ADR rows
$Rows = @()
Get-ChildItem -Path $AdrRoot -Recurse -Depth 1 -Filter '*.md' |
    Where-Object { $_.Name -match '^(\d{4})-' } |
    Sort-Object Name |
    ForEach-Object {
        $File      = $_
        $FileName  = $File.Name
        $Subfolder = $File.Directory.Name
        $Num       = $Matches[1]

        # Extract status from frontmatter
        $Lines     = Get-Content $File.FullName -Encoding UTF8
        $Status    = 'unknown'
        $Title     = ''
        $InFront   = $false
        $FrontDone = $false

        foreach ($Line in $Lines) {
            if ($Line -eq '---') {
                if (-not $InFront -and -not $FrontDone) { $InFront = $true; continue }
                else { $FrontDone = $true; $InFront = $false; continue }
            }
            if ($InFront -and $Line -match '^status:\s*"?([^"]+)"?\s*$') {
                $Status = $Matches[1].Trim('"')
            }
            if ($FrontDone -and $Title -eq '' -and $Line -match '^#\s+(.+)$') {
                $Title = $Matches[1]
            }
        }

        if ($Title -eq '') {
            $Title = ($FileName -replace '^\d+-', '') -replace '-', ' '
        }

        $RelPath = "adr/$Subfolder/$FileName"
        $Rows += [PSCustomObject]@{
            Num       = $Num
            Subfolder = $Subfolder
            Status    = $Status
            Title     = $Title
            RelPath   = $RelPath
        }
    }

# Build markdown table
$TableLines = @()
$TableLines += '| № | Тема | Статус | Заголовок |'
$TableLines += '|---|---|---|---|'
foreach ($Row in $Rows) {
    $TableLines += "| $($Row.Num) | $($Row.Subfolder) | $($Row.Status) | [$($Row.Title)]($($Row.RelPath)) |"
}
$Table = $TableLines -join "`n"

# Replace content between markers
$IndexContent = Get-Content $IndexFile -Encoding UTF8
$Output       = @()
$InBlock      = $false

foreach ($Line in $IndexContent) {
    if ($Line -eq $StartMarker) {
        $Output  += $Line
        $Output  += $Table
        $InBlock  = $true
        continue
    }
    if ($Line -eq $EndMarker) {
        $InBlock = $false
    }
    if (-not $InBlock) {
        $Output += $Line
    }
}

[System.IO.File]::WriteAllLines($IndexFile, $Output, [System.Text.Encoding]::UTF8)
Write-Host "Updated: $IndexFile ($($Rows.Count) ADR entries)"
