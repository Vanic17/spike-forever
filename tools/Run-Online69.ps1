$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.runtime/online69-data'
$base=@('--headless','--path',('"'+$root+'"'),'--script','tools/Test-OnlineSubstitution69.gd')
$host68=Start-Process -FilePath $engine -ArgumentList $base -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/online69-host.log') -RedirectStandardError (Join-Path $root '.runtime/online69-host-errors.log')
Start-Sleep -Seconds 3
$guest68=Start-Process -FilePath $engine -ArgumentList ($base+@('--','--guest')) -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root '.runtime/online69-guest.log') -RedirectStandardError (Join-Path $root '.runtime/online69-guest-errors.log')
Wait-Process -Id $host68.Id,$guest68.Id -Timeout 55
foreach($role in @('host','guest')){
 $log=Get-Content -Raw (Join-Path $root ('.runtime/online69-'+$role+'.log'))
 $errors=Get-Content -Raw (Join-Path $root ('.runtime/online69-'+$role+'-errors.log'))
 if($log -notmatch 'ONLINE SUBSTITUTION69 PASS' -or $errors -match 'SCRIPT ERROR|Parse Error|ONLINE68 FAIL'){throw ('Online69 failed '+$role)}
 $log -split "`n" | Select-Object -Last 2
}
