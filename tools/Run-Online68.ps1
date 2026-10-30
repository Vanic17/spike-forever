$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.runtime/online68-data'
$base=@('--headless','--path',('"'+$root+'"'),'--script','tools/Test-OnlineSubstitution68.gd')
$host68=Start-Process -FilePath $engine -ArgumentList $base -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/online68-host.log') -RedirectStandardError (Join-Path $root '.runtime/online68-host-errors.log')
Start-Sleep -Seconds 3
$guest68=Start-Process -FilePath $engine -ArgumentList ($base+@('--','--guest')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/online68-guest.log') -RedirectStandardError (Join-Path $root '.runtime/online68-guest-errors.log')
Wait-Process -Id $host68.Id,$guest68.Id -Timeout 55
foreach($role in @('host','guest')){
 $log=Get-Content -Raw (Join-Path $root ('.runtime/online68-'+$role+'.log'))
 $errors=Get-Content -Raw (Join-Path $root ('.runtime/online68-'+$role+'-errors.log'))
 if($log -notmatch 'ONLINE SUBSTITUTION68 PASS' -or $errors -match 'SCRIPT ERROR|Parse Error|ONLINE68 FAIL'){throw ('Online68 failed '+$role)}
 $log -split "`n" | Select-Object -Last 2
}
