param([Parameter(Mandatory)][string]$Url,[Parameter(Mandatory)][string]$ExpectedHash)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$target=Join-Path $root '.runtime/update75-download.zip'
if($Url -notmatch '^https://github\.com/Vanic17/spike-forever/releases/download/'){throw 'Not an official package URL'}
Add-Type -AssemblyName System.Net.Http
$client=[Net.Http.HttpClient]::new(); $client.Timeout=[TimeSpan]::FromMinutes(60)
$client.DefaultRequestHeaders.UserAgent.ParseAdd('Spike-Forever-Updater-Test')
$watch=[Diagnostics.Stopwatch]::StartNew()
try{
 $response=$client.GetAsync($Url,[Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
 $response.EnsureSuccessStatusCode() | Out-Null
 $inputStream=$response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
 $outputStream=[IO.File]::Create($target)
 try{$inputStream.CopyTo($outputStream)}finally{$outputStream.Dispose();$inputStream.Dispose()}
 $actual=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
 if($actual -ne $ExpectedHash.ToLowerInvariant()){throw 'Official package checksum mismatch'}
 @{pass=$true;url=$Url;bytes=(Get-Item -LiteralPath $target).Length;sha256=$actual;seconds=$watch.Elapsed.TotalSeconds;installed=$false} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root 'docs/update75-live-download.json')
 Write-Output 'LIVE DOWNLOAD75 PASS: complete official package verified; no installation performed'
}finally{$client.Dispose()}
