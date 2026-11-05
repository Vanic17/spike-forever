$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$fixture=Join-Path $root ('.runtime/update75-'+[guid]::NewGuid().ToString('N'))
$game=Join-Path $fixture 'game'
New-Item -ItemType Directory -Force $game | Out-Null
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$project="config_version=5`n[application]`nconfig/name=`"Spike Forever`"`n"
[IO.File]::WriteAllText((Join-Path $game 'project.godot'),$project)
[IO.File]::WriteAllText((Join-Path $game 'version.json'),'{"version":"0.20.0"}')
[IO.File]::WriteAllText((Join-Path $game 'controls.cfg'),'personal controls')
$personal=@('roster-overrides.json','careers/slot.json','legend72/legend-01.json','settings.cfg')
foreach($p in $personal){
 $path=Join-Path $game $p
 New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
 [IO.File]::WriteAllText($path,'personal '+$p)
}
$hashes=@{}; foreach($p in $personal+@('controls.cfg')){$hashes[$p]=(Get-FileHash -LiteralPath (Join-Path $game $p)).Hash}
function Package([string]$Path,[string]$Extra='', [bool]$Rename=$false){
 $payload=@{'project.godot'=$project;'src/main.gd'='extends Node3D';'version.json'='{"version":"0.75.0"}';'Avvia Spike Forever.cmd'='@echo off';'controls.cfg'='default controls'}
 if($Rename){$payload['project.godot']=$project.Replace('Spike Forever','Wrong Save Folder')}
 if($Extra){$payload[$Extra]='overwrite attempt'}
 $manifest=@{version='0.75.0';files=@{}}
 $zip=[IO.Compression.ZipFile]::Open($Path,[IO.Compression.ZipArchiveMode]::Create)
 try{
  foreach($p in $payload.Keys){
   $bytes=[Text.Encoding]::UTF8.GetBytes($payload[$p])
   $manifest.files[$p]=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
   $stream=$zip.CreateEntry($p).Open();try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
  }
  $writer=[IO.StreamWriter]::new($zip.CreateEntry('release-manifest.json').Open())
  try{$writer.Write(($manifest | ConvertTo-Json -Depth 8))}finally{$writer.Dispose()}
 }finally{$zip.Dispose()}
}
$results=@()
foreach($case in @('skip-versions','protect-roster','protect-career','protect-legend','protect-settings','protect-save-identity')){
 $path=Join-Path $fixture ($case+'.zip')
 $extra=switch($case){'protect-roster'{'roster-overrides.json'}'protect-career'{'careers/slot.json'}'protect-legend'{'legend72/legend-01.json'}'protect-settings'{'settings.cfg'}default{''}}
 Package $path $extra ($case -eq 'protect-save-identity')
 $rejected=$false
 try{& (Join-Path $root 'tools/Install-Update.ps1') -Archive $path -Destination $game -ExpectedHash (Get-FileHash -LiteralPath $path).Hash -NoRestart}catch{$rejected=$true}
 if(($case -eq 'skip-versions') -eq $rejected){throw ('Wrong install result: '+$case)}
 foreach($p in $hashes.Keys){if((Get-FileHash -LiteralPath (Join-Path $game $p)).Hash -ne $hashes[$p]){throw ('Personal data changed: '+$p)}}
 if((Get-Content -Raw (Join-Path $game 'version.json') | ConvertFrom-Json).version -ne '0.75.0'){throw 'Installed version damaged'}
 $results+=@{case=$case;pass=$true;rejected=$rejected}
}
@{pass=$true;cases=$results;fixture=$fixture;personal_files=$hashes.Keys}|ConvertTo-Json -Depth 6|Set-Content -Encoding UTF8 (Join-Path $root 'docs/update75-preservation.json')
Write-Output 'UPDATE75 PASS: skipping versions, personal files and save identity protected'
