$marker = "C:\Windows\Temp\i_am_here.txt"
$info = @"
hostname: $env:COMPUTERNAME
user:     $env:USERNAME
os:       $([System.Environment]::OSVersion.VersionString)
time:     $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
arch:     $env:PROCESSOR_ARCHITECTURE
"@
$info | Out-File -FilePath $marker -Encoding utf8 -Force