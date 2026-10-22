param([string]$Repository='Vanic17/spike-forever',[string]$Package='')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$env:GH_CONFIG_DIR=Join-Path $root 'tools/github/config'
$gh=Join-Path $root 'tools/github/bin/gh.exe'
$git=Join-Path $root 'tools/git/cmd/git.exe'
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
foreach($name in @('Build-Release.ps1','Publish-Release.ps1','Bootstrap-Engine.ps1')){Copy-Item (Join-Path $root ('tools/'+$name)) (Join-Path $stage ('tools/'+$name))}
foreach($file in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File){
 if($file.Name -like 'Test-*' -or $file.Name -like 'Check-*'){
  Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $stage ('tools/'+$file.Name))
 }
}
foreach($baseline in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Directory -Filter 'baseline*'){
 Copy-Item -LiteralPath $baseline.FullName -Destination (Join-Path $stage 'docs') -Recurse
}
Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter '*.md' | Copy-Item -Destination (Join-Path $stage 'docs')
[IO.File]::WriteAllText((Join-Path $stage '.gitignore'), ".godot/`n.runtime/`n.updates/`ndist/`nupdate-result.json`ntools/godot/`ntools/git/`ntools/github/`ndocs/*-test.log`n")
Native $git @('-C',$stage,'init','--initial-branch=main')
Native $git @('-C',$stage,'config','user.name','Vanic17')
Native $git @('-C',$stage,'config','user.email','264198889+Vanic17@users.noreply.github.com')
Native $git @('-C',$stage,'remote','add','origin',('https://github.com/'+$Repository+'.git'))
$helper='credential.helper=!gh auth git-credential'
Native $git @('-C',$stage,'-c',$helper,'fetch','origin','main') -AllowFailure
if($script:LastNativeExit -eq 0){Native $git @('-C',$stage,'reset','--mixed','origin/main')}
Native $git @('-C',$stage,'add','--all')
Native $git @('-C',$stage,'commit','-m',('Spike Forever '+$tag))
Native $git @('-C',$stage,'-c',$helper,'push','origin','main')
Native $gh @('release','create',$tag,$package,'--repo',$Repository,'--title',('Spike Forever '+$tag),'--notes',('Versione '+$version+'. Pacchetto Windows completo. Installazione e versioni precedenti dal menu iniziale.'))
[IO.File]::WriteAllText((Join-Path $root 'dist/published-package.txt'),$package)
Write-Output ('PUBLISHED https://github.com/'+$Repository+'/releases/tag/'+$tag)
