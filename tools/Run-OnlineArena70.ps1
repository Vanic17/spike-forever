$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.runtime/arena70-online-data'
$args70=@('--headless','--path',('"'+$root+'"'),'--script','tools/Test-OnlineArena70.gd')
$host70=Start-Process -FilePath $engine -ArgumentList $args70 -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/arena70-online-host.log') -RedirectStandardError (Join-Path $root '.runtime/arena70-online-host-errors.log')
Start-Sleep -Seconds 3
$guest70=Start-Process -FilePath $engine -ArgumentList ($args70+@('--','--guest')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/arena70-online-guest.log') -RedirectStandardError (Join-Path $root '.runtime/arena70-online-guest-errors.log')
Wait-Process -Id $host70.Id,$guest70.Id -Timeout 55
foreach($role70 in @('host','guest')){
 $log70=Get-Content -Raw (Join-Path $root ('.runtime/arena70-online-'+$role70+'.log'))
 $errors70=Get-Content -Raw (Join-Path $root ('.runtime/arena70-online-'+$role70+'-errors.log'))
 if($log70 -notmatch 'ONLINE ARENA70 PASS' -or $errors70 -match 'SCRIPT ERROR|Parse Error|ONLINE68 FAIL'){throw ('Online arena70 failed '+$role70)}
 $log70 -split "`n" | Select-Object -Last 2
}
