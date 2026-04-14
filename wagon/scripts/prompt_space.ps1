# prompt_space.ps1

$profileContent = @'

# prompt space
function prompt {
    " " + (Get-Location).Path + "> "
}
'@

$profilePaths = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\PowerShell\profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
)

foreach ($p in $profilePaths) {
    $dir = Split-Path $p
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $existing = if (Test-Path $p) { Get-Content $p -Raw } else { "" }
    if ($existing -notmatch "# prompt space") {
        Add-Content -Path $p -Value $profileContent -Force
    }
}

# also hit the all users profile locations
$allUsersProfiles = @(
    "$env:ProgramFiles\PowerShell\7\profile.ps1",
    "$env:SystemRoot\System32\WindowsPowerShell\v1.0\profile.ps1"
)

foreach ($p in $allUsersProfiles) {
    $dir = Split-Path $p
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $existing = if (Test-Path $p) { Get-Content $p -Raw } else { "" }
    if ($existing -notmatch "# prompt space") {
        Add-Content -Path $p -Value $profileContent -Force
    }
}