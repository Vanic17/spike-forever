$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$processes106=@()
foreach($role106 in @('host','guest')){
 $env:APPDATA=Join-Path $root ('.runtime/serve106/online-'+$role106+'/roaming')
 $env:LOCALAPPDATA=Join-Path $root ('.runtime/serve106/online-'+$role106+'/local')
 $arguments106=@('--headless','--path','.','--script','tools/Test-OnlineServe106.gd')
 if($role106 -eq 'guest'){$arguments106+=@('--','--guest')}
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments106 -WindowStyle Hidden -PassThru -RedirectStandardOutput ('.runtime/serve106-online-'+$role106+'.log') -RedirectStandardError ('.runtime/serve106-online-'+$role106+'.err')
 $handle106=$p.Handle;$processes106+=$p
 if($role106 -eq 'host'){Start-Sleep -Seconds 2}
}
foreach($p in $processes106){if(!$p.WaitForExit(50000)){Stop-Process -Id $p.Id;throw 'Online106 timeout'}}
foreach($role106 in @('host','guest')){
 $stdout106=Get-Content -Raw ('.runtime/serve106-online-'+$role106+'.log')
 $stderr106=Get-Content -Raw ('.runtime/serve106-online-'+$role106+'.err')
 if(!$stdout106.Contains('ONLINE106 PASS') -or $stderr106 -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|Assertion failed'){throw ('Online106 failed '+$role106)}
}
Write-Output 'ONLINE106 BOTH CLIENTS PASS'
