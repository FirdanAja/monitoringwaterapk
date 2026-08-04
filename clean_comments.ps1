$files = Get-ChildItem -Path "d:\SKRIPSIIIIIIIIIIIIIII\apkmonitoring\monitoringwaterapk\lib" -Filter *.dart -Recurse
foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    $cleaned = @()
    foreach ($line in $lines) {
        if ($line -match '^\s*//') {
            continue
        }
        if ($line -match '//' -and $line -notmatch 'https?://') {
            $line = $line -replace '\s*//.*$', ''
        }
        $cleaned += $line
    }
    Set-Content -Path $file.FullName -Value $cleaned
}
Write-Host "Pembersihan komentar selesai!"
