$marker = "C:\Windows\Temp\i_was_here.txt"
$id = whoami /all 2>&1
$id | Out-File -FilePath $marker -Encoding utf8 -Force