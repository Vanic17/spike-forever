$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$base=@('--headless','--path','.', '--script','tools/Test-OnlineReplay65.gd')
$processes=@()
foreach($role85 in @('host','guest')) {
 $env:APPDATA=Join-Path $root ('.runtime/graphics85-replay-'+$role85+'-appdata')
 $env:LOCALAPPDATA=Join-Path $root ('.runtime/graphics85-replay-'+$role85+'-local')
 $args85=$base
 if($role85 -eq 'guest'){$args85+=@('--','--guest')}
 $processes+=Start-Process $engine -ArgumentList $args85 -WindowStyle Hidden -PassThru -RedirectStandardOutput ('.runtime/graphics85-replay-'+$role85+'.stdout.log') -RedirectStandardError ('.runtime/graphics85-replay-'+$role85+'.stderr.log')
 if($role85 -eq 'host'){Start-Sleep -Seconds 3}
}
foreach($p in $processes){if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw 'Online replay timeout'}}
foreach($role85 in @('host','guest')) {
 $output85=Get-Content -Raw ('.runtime/graphics85-replay-'+$role85+'.stdout.log')
 $errors85=Get-Content -Raw ('.runtime/graphics85-replay-'+$role85+'.stderr.log')
 if($output85 -notmatch 'ONLINE REPLAY66 PASS' -or $errors85 -match 'SCRIPT ERROR|Parse Error|Assertion failed|SHADER ERROR'){throw ('Replay failed '+$role85)}
 Write-Output ('PASS online replay '+$role85)
}
