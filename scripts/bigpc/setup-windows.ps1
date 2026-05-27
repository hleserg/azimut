# setup-windows.ps1 — настраивает Windows на bigPC для проброса WSL:8080 в LAN.
# Запускать в Windows PowerShell ОТ АДМИНИСТРАТОРА.
# Идемпотентный: безопасно перезапускать.
#
# Что делает:
#   1. Создаёт C:\scripts\ (если нет) и копирует туда wsl-portproxy.ps1.
#   2. Создаёт inbound firewall rule на TCP 8080 (Private + Domain профили).
#   3. Регистрирует Scheduled Task "WSL Portproxy 8080" — запуск при логоне
#      с правами админа, переустанавливает portproxy на текущий WSL IP.
#   4. Запускает task сразу, без перезагрузки.
#   5. Показывает текущие portproxy-правила.
#
# Документация: scripts/bigpc/README.md
# План: docs/_planning/05-rebuild-plan.md раздел 4.1 (вариант Б)

#Requires -Version 5.1
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$port            = 8080
$scriptsDir      = 'C:\scripts'
$workerName      = 'wsl-portproxy.ps1'
$workerSrc       = Join-Path $PSScriptRoot $workerName
$workerDst       = Join-Path $scriptsDir $workerName
$firewallName    = 'Structurizr Lite 8080'
$taskName        = 'WSL Portproxy 8080'

if (-not (Test-Path $workerSrc)) {
    Write-Error "Worker script not found at $workerSrc — make sure you run this from scripts/bigpc/ or have wsl-portproxy.ps1 next to setup-windows.ps1."
    exit 1
}

Write-Host '==> 1/5: Preparing C:\scripts\'
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir | Out-Null
    Write-Host "    Created $scriptsDir"
} else {
    Write-Host "    $scriptsDir already exists"
}
Copy-Item -Path $workerSrc -Destination $workerDst -Force
Write-Host "    Copied $workerName -> $workerDst"

Write-Host ''
Write-Host '==> 2/5: Firewall rule'
$existing = Get-NetFirewallRule -DisplayName $firewallName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "    Firewall rule '$firewallName' already exists — skipping"
} else {
    New-NetFirewallRule -DisplayName $firewallName `
        -Direction Inbound -Action Allow `
        -Protocol TCP -LocalPort $port `
        -Profile Private,Domain | Out-Null
    Write-Host "    Created firewall rule '$firewallName' (TCP $port, Private+Domain)"
    Write-Host "    Note: if your network is classified 'Public', либо переключи сеть в 'Private',"
    Write-Host "          либо добавь '-Profile Public' — но это менее безопасно."
}

Write-Host ''
Write-Host '==> 3/5: Scheduled Task'
$old = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($old) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "    Removed existing task '$taskName' (will recreate)"
}

$action    = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$workerDst`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName `
    -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings | Out-Null
Write-Host "    Registered '$taskName' (runs at logon, Highest privileges)"

Write-Host ''
Write-Host '==> 4/5: Running task once now'
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 5
$info = Get-ScheduledTaskInfo -TaskName $taskName
Write-Host "    LastRunTime:      $($info.LastRunTime)"
Write-Host "    LastTaskResult:   $($info.LastTaskResult)  (0 = success)"

Write-Host ''
Write-Host '==> 5/5: Current portproxy state'
& netsh interface portproxy show all

Write-Host ''
Write-Host '============================================================'
Write-Host 'Windows side configured.'
Write-Host 'Test from another machine in LAN:'
Write-Host "  http://bigPC:$port"
Write-Host '(если bigPC не резолвится — используй IP, либо добавь запись в hosts/router DNS)'
Write-Host ''
Write-Host 'Если portproxy после reboot не появится — проверь:'
Write-Host '  - WSL встал ли:   wsl -l -v'
Write-Host '  - Task сработал:  Get-ScheduledTaskInfo -TaskName "WSL Portproxy 8080"'
Write-Host '  - Запусти вручную: Start-ScheduledTask -TaskName "WSL Portproxy 8080"'
Write-Host '============================================================'
