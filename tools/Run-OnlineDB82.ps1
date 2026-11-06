$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$args82=@('--headless','--path',('"'+$root+'"'),'--script','tools/Test-OnlineDB82.gd')
$env:APPDATA=Join-Path $root '.runtime/online82-host-data'
$env:LOCALAPPDATA=Join-Path $root '.runtime/online82-host-local'
$host82=Start-Process $engine -ArgumentList $args82 -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput .runtime/online82-host.log -RedirectStandardError .runtime/online82-host-errors.log
Start-Sleep -Seconds 3
$env:APPDATA=Join-Path $root '.runtime/online82-guest-data'
$env:LOCALAPPDATA=Join-Path $root '.runtime/online82-guest-local'
$guest82=Start-Process $engine -ArgumentList ($args82+@('--','--guest')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput .runtime/online82-guest.log -RedirectStandardError .runtime/online82-guest-errors.log
Wait-Process -Id $host82.Id,$guest82.Id -Timeout 45
foreach($role82 in @('host','guest')){
 $log82=Get-Content -Raw ('.runtime/online82-'+$role82+'.log')
 $err82=Get-Content -Raw ('.runtime/online82-'+$role82+'-errors.log')
 if($log82 -notmatch 'ONLINE82 DATABASE PASS' -or $err82 -match 'SCRIPT ERROR|Parse Error|ONLINE82 FAIL'){throw ('Online database failed '+$role82)}
 $log82 -split "`n" | Select-Object -Last 2
}
