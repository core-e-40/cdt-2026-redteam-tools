# prompt_space_task.ps1

$enforcePath = "C:\Windows\System32\spool\prompt_space.ps1"

$lines = @(
    '$profileContent = "# prompt space`nfunction prompt {`n    "" "" + (Get-Location).Path + ""> ""`n}"',
    '',
    '$profilePaths = @(',
    '    "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1",',
    '    "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1",',
    '    "$env:ProgramFiles\PowerShell\7\profile.ps1"',
    ')',
    '',
    'foreach ($p in $profilePaths) {',
    '    $dir = Split-Path $p',
    '    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }',
    '    $existing = if (Test-Path $p) { Get-Content $p -Raw } else { "" }',
    '    if ($existing -notmatch "# prompt space") {',
    '        Add-Content -Path $p -Value $profileContent -Force',
    '    }',
    '}'
)

Set-Content -Path $enforcePath -Value $lines -Encoding utf8 -Force

# run immediately
& powershell.exe -ExecutionPolicy Bypass -File $enforcePath

# scheduled task
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
    -TaskName "TerminalSessionManager" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force