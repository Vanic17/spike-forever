param([Parameter(Mandatory)][string]$Archive,[Parameter(Mandatory)][string]$Destination,[Parameter(Mandatory)][string]$ExpectedHash,[int]$WaitPid=0,[switch]$NoRestart)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
if($ExpectedHash -notmatch '^[0-9a-fA-F]{64}$' -or (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash -ne $ExpectedHash){throw 'Archive checksum mismatch'}
if($WaitPid -gt 0){Wait-Process -Id $WaitPid -ErrorAction SilentlyContinue}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$transaction=Join-Path $root ('.updates/'+[guid]::NewGuid().ToString('N'))
$stage=Join-Path $transaction 'stage'
$backup=Join-Path $transaction 'backup'
New-Item -ItemType Directory -Force $stage,$backup | Out-Null
$changed=[Collections.Generic.List[string]]::new()
$newFiles=[Collections.Generic.List[string]]::new()
try {
 $zip=[IO.Compression.ZipFile]::OpenRead($Archive)
 try {
  $seen=@{}
  foreach($entry in $zip.Entries){
   $name=$entry.FullName.Replace('\','/')
   if(!$name -or $name.EndsWith('/')){continue}
   if($name.StartsWith('/') -or $name.Contains(':') -or $name.Split('/') -contains '..' -or $seen.ContainsKey($name.ToLowerInvariant())){throw 'Unsafe or duplicate archive path'}
   if($name -match '^(\.git|\.runtime|\.updates|user|userdata|saves|careers|legend72)(/|$)' -or $name -match '(^|/)(roster-overrides\.json|settings\.cfg|legend-\d+\.json|career-\d+\.json)(\.|$)' -or (($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960){throw 'Unsafe or personal-data archive entry'}
   $seen[$name.ToLowerInvariant()]=$true
   $path=[IO.Path]::GetFullPath((Join-Path $stage $name))
   if(!$path.StartsWith($stage+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Archive escaped staging'}
   New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
   [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$path,$false)
  }
 } finally {$zip.Dispose()}
 $manifest=Get-Content -Raw -LiteralPath (Join-Path $stage 'release-manifest.json') | ConvertFrom-Json
 $selective=$manifest.mode -eq 'file-scan'
 # A renamed Godot application silently selects a different AppData folder,
 # making existing careers/overrides look lost even without deleting them.
 $projectSource=Join-Path $stage 'project.godot'
 if($selective -and !(Test-Path -LiteralPath $projectSource)){$projectSource=Join-Path $root 'project.godot'}
 $projectText=Get-Content -Raw -LiteralPath $projectSource
 $installedProject=Join-Path $root 'project.godot'
 if(Test-Path -LiteralPath $installedProject){
  $installedText=Get-Content -Raw -LiteralPath $installedProject
  foreach($setting in @('config/name','config/use_custom_user_dir','config/custom_user_dir_name')){
   $pattern='(?m)^'+[regex]::Escape($setting)+'=(.*)$'
   $oldValue=[regex]::Match($installedText,$pattern).Groups[1].Value.Trim()
   $newValue=[regex]::Match($projectText,$pattern).Groups[1].Value.Trim()
   if($oldValue -ne $newValue){throw ('Update changes the save-data identity: '+$setting)}
  }
 }
 foreach($required in @('project.godot','src/main.gd','version.json','Avvia Spike Forever.cmd')){
  if(!$manifest.files.PSObject.Properties[$required]){throw ('Missing required release file: '+$required)}
 }
 foreach($property in $manifest.files.PSObject.Properties){
  $relative=$property.Name
  # A selective payload lists the entire target version, including unchanged
  # files. Verify those again after the game exits, before changing anything.
  if($relative.StartsWith('/') -or $relative.Contains(':') -or $relative.Contains('\') -or $relative.Split('/') -contains '..' -or $relative.Split('/') -contains '' -or $relative -match '^(\.git|\.runtime|\.updates|user|userdata|saves|careers|legend72)(/|$)' -or $relative -match '(^|/)(roster-overrides\.json|settings\.cfg|legend-\d+\.json|career-\d+\.json)(\.|$)'){throw 'Unsafe manifest path'}
  if(Test-Path -LiteralPath (Join-Path $root $relative) -PathType Container){throw 'Required file path is occupied by a directory'}
  if(!$seen.ContainsKey($relative.ToLowerInvariant()) -and !$selective){throw 'Manifest references missing file'}
  $from=Join-Path $stage $relative
  if(!$seen.ContainsKey($relative.ToLowerInvariant())){
   $from=Join-Path $root $relative
   if($relative -eq 'controls.cfg' -and (Test-Path -LiteralPath $from)){continue}
   $probe=$from
   while($probe.Length -ge $root.Length){
    if((Test-Path -LiteralPath $probe) -and ((Get-Item -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Installation contains redirected file'}
    $probe=Split-Path $probe
   }
  }
  if((Get-FileHash -LiteralPath $from -Algorithm SHA256).Hash -ne $property.Value){throw ('File verification failed: '+$relative)}
 }
 foreach($relative in $seen.Keys){
  if($relative -ne 'release-manifest.json' -and !$manifest.files.PSObject.Properties[$relative]){throw 'Unlisted archive payload'}
 }
 foreach($property in $manifest.files.PSObject.Properties){
  $relative=$property.Name
  if($selective -and !$seen.ContainsKey($relative.ToLowerInvariant())){continue}
  $target=Join-Path $root $relative
  if($relative -eq 'controls.cfg' -and (Test-Path -LiteralPath $target)){continue}
  # Refuse junctions/symlinks in the existing installation as well.
  $parent=Split-Path $target
  while($parent.Length -gt $root.Length){
   if((Test-Path -LiteralPath $parent) -and ((Get-Item -LiteralPath $parent).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Installation contains a redirected directory'}
   $parent=Split-Path $parent
  }
  if(Test-Path -LiteralPath $target){
   if((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Installation contains redirected file'}
   $saved=Join-Path $backup $relative
   New-Item -ItemType Directory -Force (Split-Path $saved) | Out-Null
   Copy-Item -LiteralPath $target -Destination $saved
   $changed.Add($relative)
  }else{$newFiles.Add($relative)}
  New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
  Copy-Item -LiteralPath (Join-Path $stage $relative) -Destination $target -Force
 }
 [IO.File]::WriteAllText((Join-Path $root 'update-result.json'),(@{success=$true;message=('Versione '+$manifest.version+' installata.')} | ConvertTo-Json))
}catch{
 foreach($relative in $changed){Copy-Item -LiteralPath (Join-Path $backup $relative) -Destination (Join-Path $root $relative) -Force}
 foreach($relative in $newFiles){$target=Join-Path $root $relative; if(Test-Path -LiteralPath $target){Remove-Item -LiteralPath $target -Force}}
 [IO.File]::WriteAllText((Join-Path $root 'update-result.json'),(@{success=$false;message=('Installazione annullata, versione precedente ripristinata: '+$_.Exception.Message)} | ConvertTo-Json))
 if($NoRestart){throw}
}finally{
 if(!$NoRestart){Start-Process -FilePath (Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64.exe') -ArgumentList @('--path',('"'+$root+'"')) -WorkingDirectory $root -WindowStyle Hidden}
}
