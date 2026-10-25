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
$files+=@('docs/RELEASE_NOTES_43.md','docs/preparation43-before.json','docs/preparation43-after.json','tools/Test-RecoveryPresentation43.gd','tools/Benchmark-Preparation43.gd')
$files+=@('docs/RELEASE_NOTES_44.md','docs/attacks44-preview.mp4','docs/balance44-report.json','docs/first-tempo44-report.json')
$files+='docs/RELEASE_NOTES_45.md'
$files+='docs/RELEASE_NOTES_45_1.md'
$files+='docs/RELEASE_NOTES_46.md'
$files+='docs/RELEASE_NOTES_47.md'
$files+='docs/RELEASE_NOTES_48.md'
$files+=@('docs/RELEASE_NOTES_49.md','docs/match49-report.json','docs/match-menu49.png','tools/Test-MatchSetup49.gd','tools/Capture-MatchMenu49.gd')
$files+=@('docs/RELEASE_NOTES_50.md','docs/running50-preview.mp4','docs/running50-report-30.json','docs/running50-report-60.json','docs/running50-report-120.json','tools/Test-RunningAttack50.gd','tools/Preview-RunningAttack50.gd')
$files+=@('docs/crossing50-report.json','tools/Test-OutsideCrossing50.gd')
$files+=@('docs/RELEASE_NOTES_51.md','docs/preferences51-report.json','docs/handed51-report.json','docs/online51-host.json','docs/online51-guest.json','docs/discovery51-report.json','docs/menu51-home.png','docs/menu51-online.png','docs/menu51-preferences.png')
$files+='docs/handed51-preview.png'
$files+=@('docs/RELEASE_NOTES_52.md','docs/rally52-report.json','docs/block52-balance.json','docs/contact-traffic28-report.json','docs/baseline-v51/block_response.gd','docs/baseline-v51/shot_variation.gd','tools/Test-RallyFix52.gd','tools/Test-BlockBalance52.gd','tools/Test-ContactTraffic28.gd','tools/Test-RecoveryTraffic.gd')
$files+='docs/rally52-psa-report.json'
$files+='tools/Capture-Recovery52.gd'
foreach($preview52 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'recovery52-preview-*.png'){ $files+='docs/'+$preview52.Name }
foreach($tool51 in @('Test-Preferences51.gd','Test-Handed51.gd','Test-Online51.gd','Test-HumanContacts51.gd','Test-OnlineUI51.gd','Test-LobbyLeave51.gd','Test-Discovery51.gd','Capture-Online51.gd')){ $files+='tools/'+$tool51 }
foreach($tool48 in @('Inspect-Middle48.gd','Test-FirstTempo48.gd','Preview-FirstTempo48.gd')){ $files+='tools/'+$tool48 }
foreach($report48 in @('first-tempo48-report.json','first-tempo48-preview.mp4','first-tempo48-set-0.png','first-tempo48-set-1.png','first-tempo48-set-2.png','first-tempo48-hit.png','first-tempo48-feint.png','approach48-contacts.json')){ $files+='docs/'+$report48 }
foreach($tool47 in @('Fetch-PlayerReferences47.py','Prepare-Appearance47.py','Build-PlayerProfiles47.py','Inspect-Contacts47.gd','Test-Tips47.gd','Test-Gameplay47.gd','Test-BlockRallies47.gd','Test-Appearance47.gd','Test-ProfileOverrides47.gd','Preview-Appearance47.gd','Benchmark-Rendered47.gd')){
 $files+='tools/'+$tool47
}
foreach($report47 in @('appearance47-sources.json','appearance47-presets.png','tips47-report.json','gameplay47-report.json','block-rallies47-report.json')){
 $files+='docs/'+$report47
}
foreach($tool46 in @('Inspect-Officials46.py','Prepare-Officials46.py','Build-Officials46.gd','Build-KitPreviews46.gd','Test-Equipment46.gd','Test-Preparation46.gd','Capture-Equipment46.gd','Capture-MatchMenu46.gd','Preview-Approaches46.gd')){
 $files+='tools/'+$tool46
}
foreach($report46 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'equipment46-*.png' -or $_.Name -like 'approach46-*.png' -or $_.Name -in @('match-menu46.png','officials46-assets.json','preparation46-report.json','approach46-contact-report.json')}){
 $files+='docs/'+$report46.Name
}
foreach($kitTool in @('Build-Kits45.py','Inspect-KitMesh45.py','Fetch-KitReferences45.py','Fetch-ExtraKitReferences45.py','Test-Kits45.gd','Test-KitMatch45.gd','Preview-Kits45.gd','Benchmark-Kits45.gd','Capture-KitMatch45.gd','Check-KitScope45.py')){
 $files+='tools/'+$kitTool
}
foreach($kitReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'kits45-*.json' -or $_.Name -like 'kits45-*.png'}){
 $files+='docs/'+$kitReport.Name
}
foreach($taskTool in @('Preview-Attacks44.gd','Test-RallyBalance44.gd','Test-SweptBlock44.gd','Test-FirstTempo44.gd','Test-ForwardApproach44.gd')){
 $files+='tools/'+$taskTool
}
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
