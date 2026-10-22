$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$testRoot=Join-Path $root ('docs/update-test-'+[guid]::NewGuid().ToString('N'))
$destination=Join-Path $testRoot 'game'
New-Item -ItemType Directory -Force $destination | Out-Null
Set-Content (Join-Path $destination 'controls.cfg') 'personal controls'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$payload=@{'project.godot'='config_version=5';'src/main.gd'='extends Node3D';'version.json'='{"version":"test"}';'Avvia Spike Forever.cmd'='@echo off';'controls.cfg'='defaults'}
function Make-Package([string]$Path,[bool]$Unsafe,[bool]$InvalidHash){
 $zip=[IO.Compression.ZipFile]::Open($Path,[IO.Compression.ZipArchiveMode]::Create)
 try{
  $manifest=@{version='test';files=@{}}
  foreach($relative in $payload.Keys){
   $bytes=[Text.Encoding]::UTF8.GetBytes($payload[$relative])
   $hash=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
   $manifest.files[$relative]=$hash
   $entry=$zip.CreateEntry($relative)
   $stream=$entry.Open();try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
  }
  if($InvalidHash){$manifest.files['src/main.gd']='0'*64}
  if($Unsafe){$entry=$zip.CreateEntry('../escape.txt');$writer=[IO.StreamWriter]::new($entry.Open());$writer.Write('escape');$writer.Dispose()}
  $writer=[IO.StreamWriter]::new($zip.CreateEntry('release-manifest.json').Open());$writer.Write(($manifest | ConvertTo-Json -Depth 8));$writer.Dispose()
 }finally{$zip.Dispose()}
}
$installer=Join-Path $root 'tools/Install-Update.ps1'
foreach($scenario in @('valid','traversal','corrupt')){
 $archive=Join-Path $testRoot ($scenario+'.zip')
 Make-Package $archive ($scenario -eq 'traversal') ($scenario -eq 'corrupt')
 $digest=(Get-FileHash -LiteralPath $archive).Hash
 $failed=$false
 try{& $installer -Archive $archive -Destination $destination -ExpectedHash $digest -NoRestart}catch{$failed=$true}
 if($scenario -eq 'valid' -and $failed){throw 'Valid update rejected'}
 if($scenario -ne 'valid' -and !$failed){throw ('Unsafe package accepted: '+$scenario)}
 if((Get-Content (Join-Path $destination 'controls.cfg')) -ne 'personal controls'){throw 'Personal controls overwritten'}
 if(Test-Path (Join-Path $testRoot 'escape.txt')){throw 'Traversal escaped installation'}
}
Write-Output 'UPDATE INSTALLER PASS: verified package / custom controls preserved / traversal and invalid file hashes rejected / existing version preserved'
