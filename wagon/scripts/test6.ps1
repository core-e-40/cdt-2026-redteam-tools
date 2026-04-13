$marker = "C:\Windows\Temp\i_know_you.txt"
$info = @"
hostname:  $env:COMPUTERNAME
domain:    $env:USERDOMAIN
user:      $env:USERNAME
os:        $([System.Environment]::OSVersion.VersionString)
arch:      $env:PROCESSOR_ARCHITECTURE
ip:        $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127' } | Select-Object -First 1).IPAddress)
time:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
$info | Out-File -FilePath $marker -Encoding utf8 -Force