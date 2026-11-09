$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$processes96=@()
foreach($role96 in @('host','guest')){
 $env:APPDATA=Join-Path $root ('.runtime/match100/online-'+$role96+'/roaming')
 $env:LOCALAPPDATA=Join-Path $root ('.runtime/match100/online-'+$role96+'/local')
 $arguments96=@('--headless','--path','.','--script','tools/Test-OnlineMatch100.gd')
 if($role96 -eq 'guest'){$arguments96+=@('--','--guest')}
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments96 -WindowStyle Hidden -PassThru -RedirectStandardOutput ('.runtime/match100-online-'+$role96+'.log') -RedirectStandardError ('.runtime/match100-online-'+$role96+'.err')
 $handle96=$p.Handle;$processes96+=$p
 if($role96 -eq 'host'){Start-Sleep -Seconds 2}
}
foreach($p in $processes96){if(!$p.WaitForExit(65000)){Stop-Process -Id $p.Id;throw 'Online96 timeout'}}
foreach($role96 in @('host','guest')){
 $stdout96=Get-Content -Raw ('.runtime/match100-online-'+$role96+'.log')
 $stderr96=Get-Content -Raw ('.runtime/match100-online-'+$role96+'.err')
 if(!$stdout96.Contains('ONLINE100 PASS') -or $stderr96 -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|Assertion failed'){throw ('Online96 failed '+$role96)}
}
Write-Output 'ONLINE100 BOTH CLIENTS PASS'
