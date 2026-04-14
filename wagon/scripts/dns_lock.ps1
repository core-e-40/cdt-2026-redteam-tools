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