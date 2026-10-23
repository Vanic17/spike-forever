param([string]$OutputDirectory='dist',[switch]$SourceOnly)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$destination=[IO.Path]::GetFullPath((Join-Path $root $OutputDirectory))
New-Item -ItemType Directory -Force $destination | Out-Null
$files=@('project.godot','version.json','README.md','controls.cfg','Avvia Spike Forever.cmd','Spike Forever.exe','tools/Install-Update.ps1')
$files+=@('docs/REVISION_28.md','docs/RELEASE_NOTES_28.md')
$files+='docs/RELEASE_NOTES_29.md'
$files+='docs/RELEASE_NOTES_30.md'
$files+='docs/RELEASE_NOTES_31.md'
$files+='docs/RELEASE_NOTES_32.md'
$files+='docs/RELEASE_NOTES_33.md'
$files+='docs/RELEASE_NOTES_34.md'
$files+='docs/RELEASE_NOTES_35.md'
$files+='docs/RELEASE_NOTES_36.md'
$files+='docs/RELEASE_NOTES_37.md'
$files+='docs/RELEASE_NOTES_38.md'
$files+=@('docs/ARENA_38.md','docs/AUDIO_ARENA38.md')
foreach($name in @('ROLES_ROTATIONS_19.md','UPDATES_19.md','REVISION_18.md','ANIMATION_18.md','REVISION_20.md','REVISION_21.md','REVISION_22.md','REVISION_23.md','REVISION_24.md','REVISION_25.md','REVISION_26.md','REVISION_26_1.md','ANIMATION_24.md','ANIMATION_26.md','v26-rotation-audit.md','STRONG_SPIKES_V24.md','SPECIFICA_ROTazioni_5-1.md')){
 if(Test-Path (Join-Path $root ('docs/'+$name))){$files+='docs/'+$name}
}
foreach($folder in @('src','licenses','assets/ui','assets/active','assets/art','assets/arena_source','assets/mesh_source','assets/audio','assets/gameplay')){
 foreach($file in Get-ChildItem -LiteralPath (Join-Path $root $folder) -File -Recurse){
  if($file.Extension -in @('.import','.uid') -or $file.Name -eq 'native_stage1.res'){continue}
  $files+=$file.FullName.Substring($root.Length+1).Replace('\','/')
 }
}
if(!$SourceOnly){$files+='tools/godot/Godot_v4.5.1-stable_win64.exe'}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath=Join-Path $destination 'SpikeForever-Windows.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Output already exists; choose a new output directory'}
$manifest=[ordered]@{version=(Get-Content -Raw (Join-Path $root 'version.json') | ConvertFrom-Json).version;files=[ordered]@{}}
$zip=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
try{
 foreach($relative in $files){
  $file=Join-Path $root $relative
  $manifest.files[$relative]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file,$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
 }
 $entry=$zip.CreateEntry('release-manifest.json')
 $writer=[IO.StreamWriter]::new($entry.Open())
 try{$writer.Write(($manifest | ConvertTo-Json -Depth 8))}finally{$writer.Dispose()}
}finally{$zip.Dispose()}
Get-FileHash -LiteralPath $zipPath -Algorithm SHA256 | Format-List
