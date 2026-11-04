param(
    [string]$SaveDir  = "$env:USERPROFILE\AppData\LocalLow\Oni Gaming\Farmer Against Potatoes Idle",
    [string]$FileName = "fapi-save.txt",
    [string]$Salt     = "A Potato has more Chromosomes than a Human being",
    [double]$Value    = 99999999,
    [double]$MinIndex = 0,
    [string[]]$Fields = @("FreeSoul","TotalSoul"),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$savePath = Join-Path $SaveDir $FileName
if (-not (Test-Path $savePath)) {
    Write-Host "File not found: $savePath" -ForegroundColor Red
    return
}

$bytes = [System.IO.File]::ReadAllBytes($savePath)
if ($bytes.Length -lt 10 -or $bytes[0] -ne 0x1F -or $bytes[1] -ne 0x8B) {
    Write-Host "This is not a gzip file. First bytes:  $((($bytes[0..3]) | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Red
    return
}

$msIn  = New-Object System.IO.MemoryStream(,$bytes)
$gzIn  = New-Object System.IO.Compression.GZipStream($msIn,[System.IO.Compression.CompressionMode]::Decompress)
$msOut = New-Object System.IO.MemoryStream
try { $gzIn.CopyTo($msOut) } finally { $gzIn.Dispose(); $msIn.Dispose() }
$raw = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())

Write-Host "Unpacked: $($raw.Length) characters" -ForegroundColor Cyan

$sigMatch = [regex]::Match($raw, '([A-Za-z0-9+/]{43}=)\s*$')
if (-not $sigMatch.Success) {
    Write-Host "Did not find a Base64 signature at the end." -ForegroundColor Red
    return
}
$oldSig = $sigMatch.Groups[1].Value
$body   = $raw.Substring(0, $sigMatch.Index)

$firstBrace = $body.IndexOf('{')
$lastBrace  = $body.LastIndexOf('}')
$json = $body.Substring($firstBrace, $lastBrace - $firstBrace + 1)

Write-Host "Old signature: $oldSig" -ForegroundColor DarkGray

$enc       = [System.Text.Encoding]::UTF8
$saltBytes = $enc.GetBytes($Salt)

function Get-Sig([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $h = $sha.ComputeHash($saltBytes + $enc.GetBytes($text)) } finally { $sha.Dispose() }
    return [Convert]::ToBase64String($h)
}

$checkSig = Get-Sig $json
if ($checkSig -ne $oldSig) {
    Write-Host "WARNING: The original signature did not match. Continuing anyway." -ForegroundColor Yellow
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$newJson = $json

foreach ($field in $Fields) {
    $pat = '"' + [regex]::Escape($field) + '":(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    $re  = [regex]::new($pat)
    $m   = $re.Matches($newJson)
    if (-not $m.Success) {
        Write-Host "  [$field] not found in JSON — skipping" -ForegroundColor Yellow
        continue
    }
    
    $counter = 1
    foreach ($match in $m) {
        if ($counter -ge $MinIndex) {
            $oldValStr = $match.Groups[1].Value
            $oldVal    = [double]::Parse($oldValStr, $inv)
            $newValNum = $oldVal + $Value

            if ($oldValStr -match '[.\eE]') {
                $newValStr = $newValNum.ToString("R", $inv)
                if ($newValStr -notmatch '[.\eE]') { $newValStr += ".0" }
            } else {
                $newValStr = [long]$newValNum
            }

            $newJson = $newJson.Substring(0, $match.Index) + '"' + $field + '":' + $newValStr + $newJson.Substring($match.Index + $match.Length)
            Write-Host ("  [{0}] {1} + {2} -> {3}" -f $field, $oldValStr, $Value, $newValStr) -ForegroundColor Green
        }
        $counter++
    }

    
}

if ($newJson -eq $json) {
    Write-Host "Nothing has changed." -ForegroundColor Yellow
    return
}

$newSig = Get-Sig $newJson
Write-Host "New signature: $newSig" -ForegroundColor Green

$plain = $newJson + $newSig
$plainBytes = $enc.GetBytes($plain)

$msGz  = New-Object System.IO.MemoryStream
$gzOut = New-Object System.IO.Compression.GZipStream($msGz, [System.IO.Compression.CompressionLevel]::Optimal)
try { $gzOut.Write($plainBytes, 0, $plainBytes.Length) } finally { $gzOut.Dispose() }
$gzBytes = $msGz.ToArray()

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN: file NOT written. New gzip size: $($gzBytes.Length) bytes" -ForegroundColor Yellow
    return
}

$backup = $savePath + ".bak"
Copy-Item -LiteralPath $savePath -Destination $backup -Force
[System.IO.File]::WriteAllBytes($savePath, $gzBytes)


Write-Host “”

Write-Host “Done.” -ForegroundColor Green

Write-Host “  File:   $savePath” -ForegroundColor Green

Write-Host “  Size: $($gzBytes.Length) bytes (was $($bytes.Length))” -ForegroundColor Green

Write-Host “  Backup:  $backup” -ForegroundColor Green