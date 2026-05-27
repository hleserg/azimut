# wsl-portproxy.ps1 — обновляет netsh portproxy для WSL2 на текущий WSL IP.
# Вызывается Scheduled Task'ом "WSL Portproxy 8080" при логоне Windows.
# Установка/регистрация задачи — через setup-windows.ps1 (запускать вручную не нужно).
#
# Документация: scripts/bigpc/README.md
# План: docs/_planning/05-rebuild-plan.md раздел 4.1 (вариант Б)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$port = 8080
$listenAddress = '0.0.0.0'

# 1. Дождаться, пока WSL поднимется и сообщит IP (после холодного старта это может занять до минуты).
$timeoutSec = 90
$elapsed = 0
$wslIp = $null
while ($elapsed -lt $timeoutSec) {
    try {
        $raw = (wsl hostname -I 2>$null)
        if ($LASTEXITCODE -eq 0 -and $raw) {
            $candidate = ($raw -split '\s+' | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' })[0]
            if ($candidate) { $wslIp = $candidate; break }
        }
    } catch { }
    Start-Sleep -Seconds 2
    $elapsed += 2
}

if (-not $wslIp) {
    Write-Error "WSL IP not detected within ${timeoutSec}s. Is WSL installed and at least one distro present?"
    exit 1
}

Write-Host "Detected WSL IP: $wslIp"

# 2. Сносим старый proxy на этом порту и ставим новый.
& netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$listenAddress 2>$null | Out-Null
& netsh interface portproxy add    v4tov4 listenport=$port listenaddress=$listenAddress connectport=$port connectaddress=$wslIp | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "netsh portproxy add failed (exit=$LASTEXITCODE). Run from elevated PowerShell?"
    exit 1
}

Write-Host "portproxy ${listenAddress}:${port} -> ${wslIp}:${port}  OK"
Write-Host ""
Write-Host "Active portproxy rules:"
& netsh interface portproxy show all
