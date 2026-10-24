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
$files+=@('docs/RELEASE_NOTES_39.md','docs/AUDIO_ARENA39.md','docs/AUDIO_BANK_39.md')
$files+='docs/RELEASE_NOTES_40.md'
$files+=@('docs/RELEASE_NOTES_41.md','docs/ANIMATION_AUDIT_41.md','docs/ANIMATION_PERFORMANCE_41.md')
$files+=@('docs/ANIMATION_GAMEPLAY_PARITY_41.md','docs/animation41-preview.mp4')
$files+=@('docs/attack41-integrated-preview.png','docs/dive41-integrated-preview.png')
$files+=@('docs/RELEASE_NOTES_42.md','docs/PERFORMANCE_42.md','docs/approach42-preview.mp4','docs/approach42-15.png','docs/approach42-40.png','docs/approach42-63.png')
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'animation42-*.json' -or $_.Name -in @('approach42-report.json','scope42-report.json')}){
 $files+='docs/'+$taskReport.Name
}
foreach($taskTool in @('Preview-Approach42.gd','Benchmark-Rendered42.gd','Test-Approach42.gd','Test-SpecialistsPause42.gd')){
 $files+='tools/'+$taskTool
}
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'animation41-*.json'){
 $files+='docs/'+$taskReport.Name
}
foreach($taskTool in @('Build-Motion41.gd','Test-Motion41.gd','Test-MotionGameplay41.gd','Check-Motion41Scope.ps1','Audit-Animation41.gd','Audit-Dive41.gd','Audit-Attack41.gd','Capture-Animation41.gd','Preview-Motion41.gd','Benchmark-Animation41.gd','Benchmark-AnimationPrototypes41.gd','Benchmark-RenderedMotion41.gd')){
 $files+='tools/'+$taskTool
}
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
