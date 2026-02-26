$c = (Get-Content 'D:\temp_docx\word\document.xml' -Raw) -replace '<[^>]+>', ' '
$idx = $c.IndexOf('Mamdani')
if($idx -ge 0){
    $c.Substring($idx, [Math]::Min(10000, $c.Length - $idx))
} else {
    'Not found'
}
