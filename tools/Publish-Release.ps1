param([string]$Repository='Vanic17/spike-forever',[string]$Package='')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$gh=Join-Path $root 'tools/github/bin/gh.exe'
$git=Join-Path $root 'tools/git/cmd/git.exe'
if(Test-Path -LiteralPath $gh){$env:GH_CONFIG_DIR=Join-Path $root 'tools/github/config'}
else{$gh=(Get-Command gh -ErrorAction Stop).Source}
if(!(Test-Path -LiteralPath $git)){$git=(Get-Command git -ErrorAction Stop).Source}
$env:PATH=(Split-Path $gh)+';'+$env:PATH
function Native([string]$Executable,[string[]]$Arguments,[switch]$AllowFailure){
 $ErrorActionPreference='Continue'
 & $Executable @Arguments
 $result=$LASTEXITCODE
 if($result -ne 0 -and !$AllowFailure){throw ('Command failed: '+$Executable+' '+($Arguments -join ' '))}
 $script:LastNativeExit=$result
}
Native $gh @('auth','status')
$login=(Native $gh @('api','user','--jq','.login'))
if($login -ine 'Vanic17'){throw 'Authenticated account must be Vanic17'}
$version=(Get-Content -Raw (Join-Path $root 'version.json') | ConvertFrom-Json).version
$tag='v'+$version
$releaseDir='dist/'+$tag+'-'+[guid]::NewGuid().ToString('N')
if(!$Package){
 & (Join-Path $root 'tools/Build-Release.ps1') -OutputDirectory $releaseDir
 $Package=Join-Path $root ($releaseDir+'/SpikeForever-Windows.zip')
}
$package=[IO.Path]::GetFullPath($Package)
Native $gh @('repo','view',$Repository,'--json','name') -AllowFailure | Out-Null
if($script:LastNativeExit -ne 0){Native $gh @('repo','create',$Repository,'--public','--description','Spike Forever - Windows 6v6 volleyball and versioned updates')}
$stage=Join-Path $root ('dist/source-'+$version+'-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $stage | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($package,$stage)
Remove-Item -LiteralPath (Join-Path $stage 'tools/godot/Godot_v4.5.1-stable_win64.exe')
foreach($name in @('Build-Release.ps1','Publish-Release.ps1','Bootstrap-Engine.ps1','Convert-PsaAnimations.gd','Pack-NativeLibrary.gd','Capture-Shot31.gd','Capture-Coverage36.gd','Capture-TV37.gd','Capture-Arena38.gd','Build-ArenaAudio38.py','Render-ArenaAudio38.gd','Capture-Arena39.gd','Build-ArenaAudio39.py','Render-ArenaAudio39.gd','Capture-Movement40.gd','Audit-PointPoses40.gd')){Copy-Item (Join-Path $root ('tools/'+$name)) (Join-Path $stage ('tools/'+$name))}
foreach($file in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File){
 if($file.Name -like 'Test-*' -or $file.Name -like 'Check-*'){
  Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $stage ('tools/'+$file.Name))
 }
}
foreach($taskTool in @('Build-Motion41.gd','Audit-Animation41.gd','Audit-Dive41.gd','Audit-Attack41.gd','Capture-Animation41.gd','Preview-Motion41.gd','Benchmark-Animation41.gd','Benchmark-AnimationPrototypes41.gd','Benchmark-RenderedMotion41.gd')){
 Copy-Item -LiteralPath (Join-Path $root ('tools/'+$taskTool)) -Destination (Join-Path $stage ('tools/'+$taskTool))
}
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'animation41-*.json'){
 Copy-Item -LiteralPath $taskReport.FullName -Destination (Join-Path $stage 'docs')
}
foreach($taskTool in @('Preview-Approach42.gd','Benchmark-Rendered42.gd')){
 Copy-Item -LiteralPath (Join-Path $root ('tools/'+$taskTool)) -Destination (Join-Path $stage ('tools/'+$taskTool))
}
Copy-Item -LiteralPath (Join-Path $root 'tools/Benchmark-Preparation43.gd') -Destination (Join-Path $stage 'tools/Benchmark-Preparation43.gd')
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'animation42-*.json' -or $_.Name -in @('approach42-report.json','scope42-report.json')}){
 Copy-Item -LiteralPath $taskReport.FullName -Destination (Join-Path $stage 'docs')
}
foreach($taskImage in @('attack41-integrated-preview.png','dive41-integrated-preview.png','dive41-author-preview.png','animation41-preview.mp4')){
 Copy-Item -LiteralPath (Join-Path $root ('docs/'+$taskImage)) -Destination (Join-Path $stage 'docs')
}
foreach($baseline in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Directory -Filter 'baseline*'){
 Copy-Item -LiteralPath $baseline.FullName -Destination (Join-Path $stage 'docs') -Recurse -Force
}
Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter '*.md' | Copy-Item -Destination (Join-Path $stage 'docs')
if(Test-Path (Join-Path $root 'docs/menu-v20.png')){Copy-Item (Join-Path $root 'docs/menu-v20.png') (Join-Path $stage 'docs')}
foreach($report in @('v24-expanded-animations.json','strong-spikes-report.json','native-animation-report.json','animation-performance-v23-before-newclips.json','animation-performance-v24-native.json','animation-performance-v24-psa.json','v24-new-animation-performances.png','v26-rotation-coverage.json','v26-animation-accepted.json','v26-animation-catalog-report.json','animation-performance-v25-before-expansion.json','animation-performance-v25-psa-before-expansion.json','animation-performance-v26-native.json','animation-performance-v26-psa.json')){
 if(Test-Path (Join-Path $root ('docs/'+$report))){Copy-Item (Join-Path $root ('docs/'+$report)) (Join-Path $stage 'docs')}
}
Copy-Item -LiteralPath (Join-Path $root 'docs/original-animation-hashes.json') -Destination (Join-Path $stage 'docs')
$fixtures=Join-Path $stage 'docs/reference-killer-aces'
foreach($report in @('contact-traffic28-report.json','recovery-traffic-report.json','contact28-preview-0-contact.png','contact28-preview-1-contact.png','shot31-preview.png','coverage36-preview.png','tv37-preview.png','arena38-tv-preview.png','arena38-endline-preview.png','arena38-mix-waveform.png','arena38-mix-preview.wav','arena39-tv-preview.png','arena39-point-preview.png','arena39-mix-preview.wav','arena39-mix-waveform.png','audio39-render-events.json','audio39-mix-measurements.json','wall40-preview.png','regroup40-preview.png')){
 if(Test-Path (Join-Path $root ('docs/'+$report))){Copy-Item (Join-Path $root ('docs/'+$report)) (Join-Path $stage 'docs')}
}
New-Item -ItemType Directory -Force $fixtures | Out-Null
foreach($name in @('reference-profile.json','manager-settings.json')){Copy-Item -LiteralPath (Join-Path $root ('docs/reference-killer-aces/'+$name)) -Destination $fixtures}
[IO.File]::WriteAllText((Join-Path $stage '.gitignore'), ".godot/`n.runtime/`n.updates/`ndist/`nupdate-result.json`ntools/godot/`ntools/git/`ntools/github/`ndocs/*-test.log`n")
Native $git @('-C',$stage,'init','--initial-branch=main')
Native $git @('-C',$stage,'config','user.name','Vanic17')
Native $git @('-C',$stage,'config','user.email','264198889+Vanic17@users.noreply.github.com')
Native $git @('-C',$stage,'remote','add','origin',('https://github.com/'+$Repository+'.git'))
$helper='credential.helper=!gh auth git-credential'
# Reuse an already published staging repository's immutable Git objects.
# A fresh stage otherwise downloads the entire asset history for every patch.
$seed=Get-ChildItem -LiteralPath (Join-Path $root 'dist') -Directory -Filter 'source-*' | Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName '.git/refs/heads/main')} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if($seed){
 # Each former stage could itself borrow another stage. Git stops traversing
 # deep alternate chains, leaving trees unreadable despite a successful fetch.
 # Materialize immutable objects once; future stages are independent of old
 # staging directories, and fetch can still reuse the complete local history.
 $distRoot=[IO.Path]::GetFullPath((Join-Path $root 'dist'))+[IO.Path]::DirectorySeparatorChar
 $targetObjects=[IO.Path]::GetFullPath((Join-Path $stage '.git/objects'))
 if(!$targetObjects.StartsWith($distRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Git object destination outside workspace dist'}
 $queue=[Collections.Generic.Queue[string]]::new()
 $queue.Enqueue((Join-Path $seed.FullName '.git/objects'))
 $visited=@{}
 while($queue.Count -gt 0){
  $objectRoot=(Resolve-Path -LiteralPath $queue.Dequeue()).Path
  if(!$objectRoot.StartsWith($distRoot,[StringComparison]::OrdinalIgnoreCase) -or !(($objectRoot.Replace('\','/')).EndsWith('/.git/objects'))){throw 'Git object cache outside intended staging directory'}
  if($visited.ContainsKey($objectRoot)){continue}
  $visited[$objectRoot]=$true
  foreach($bucket in Get-ChildItem -LiteralPath $objectRoot -Directory -Force){
   if($bucket.Name -ne 'pack' -and $bucket.Name -notmatch '^[0-9a-f]{2}$'){continue}
   $destination=Join-Path $targetObjects $bucket.Name
   New-Item -ItemType Directory -Force $destination | Out-Null
   foreach($objectFile in Get-ChildItem -LiteralPath $bucket.FullName -File -Force){
    $targetFile=Join-Path $destination $objectFile.Name
    if(!(Test-Path -LiteralPath $targetFile)){Copy-Item -LiteralPath $objectFile.FullName -Destination $targetFile}
   }
  }
  $alternates=Join-Path $objectRoot 'info/alternates'
  if(Test-Path -LiteralPath $alternates){
   foreach($entry in Get-Content -LiteralPath $alternates){
    if(!$entry.Trim()){continue}
    $next=$entry.Trim()
    if(![IO.Path]::IsPathRooted($next)){$next=Join-Path $objectRoot $next}
    $queue.Enqueue([IO.Path]::GetFullPath($next))
   }
  }
 }
}
Native $git @('-C',$stage,'-c','credential.helper=','-c',$helper,'fetch','origin','main') -AllowFailure
if($script:LastNativeExit -eq 0){Native $git @('-C',$stage,'reset','--mixed','origin/main')}
Native $git @('-C',$stage,'add','--all')
Native $git @('-C',$stage,'commit','-m',('Spike Forever '+$tag))
Native $git @('-C',$stage,'-c','credential.helper=','-c',$helper,'push','origin','main')
$existing=(Native $gh @('release','view',$tag,'--repo',$Repository,'--json','isDraft') -AllowFailure)
if($script:LastNativeExit -eq 0){
 if(!($existing | ConvertFrom-Json).isDraft){throw ('Release already published; use a new version: '+$tag)}
 Native $gh @('release','upload',$tag,$package,'--repo',$Repository,'--clobber')
 Native $gh @('release','edit',$tag,'--repo',$Repository,'--draft=false','--latest')
}else{
 Native $gh @('release','create',$tag,$package,'--repo',$Repository,'--title',('Spike Forever '+$tag),'--notes',('Versione '+$version+'. Pacchetto Windows completo. Installazione e versioni precedenti dal menu iniziale.'))
}
[IO.File]::WriteAllText((Join-Path $root 'dist/published-package.txt'),$package)
Write-Output ('PUBLISHED https://github.com/'+$Repository+'/releases/tag/'+$tag)
