$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notmatch '127.0.0.1' -and 
    $_.IPAddress -notmatch '^169\.254\.' -and 
    $_.InterfaceAlias -notmatch 'Loopback' -and 
    $_.InterfaceAlias -notmatch 'vEthernet' 
} | Select-Object -ExpandProperty IPAddress -First 1

if ($ip) {
    $path = "d:\xamp\htdocs\thesisflutter\frontend\lib\services\api_service.dart"
    if (Test-Path $path) {
        $c = Get-Content $path -Raw
        $c = $c -replace 'static const String _pcLanUrl = .*', "static const String _pcLanUrl = 'http://$($ip):8000';"
        [System.IO.File]::WriteAllText($path, $c)
    }
}
