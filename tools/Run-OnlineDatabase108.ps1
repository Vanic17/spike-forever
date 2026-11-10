$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$processes108=@()
foreach($role108 in @('host','guest')){
 $env:APPDATA=Join-Path $root ('.runtime/online108/'+$role108+'/roaming')
 $env:LOCALAPPDATA=Join-Path $root ('.runtime/online108/'+$role108+'/local')
 $arguments108=@('--headless','--path','.','--script','tools/Test-OnlineDatabase108.gd')
 if($role108 -eq 'guest'){$arguments108+=@('--','--guest')}
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments108 -WindowStyle Hidden -PassThru -RedirectStandardOutput ('.runtime/online108/'+$role108+'.log') -RedirectStandardError ('.runtime/online108/'+$role108+'.err')
 $handle108=$p.Handle;$processes108+=$p
 if($role108 -eq 'host'){Start-Sleep -Seconds 2}
}
foreach($p in $processes108){if(!$p.WaitForExit(55000)){Stop-Process -Id $p.Id;throw 'Database108 timeout'}}
foreach($role108 in @('host','guest')){
 $out108=Get-Content -Raw ('.runtime/online108/'+$role108+'.log')
 $err108=Get-Content -Raw ('.runtime/online108/'+$role108+'.err')
 if(!$out108.Contains('DATABASE108 PASS') -or $err108 -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|Assertion failed'){throw ('Database108 failed '+$role108)}
}
Write-Output 'DATABASE108 BOTH CLIENTS PASS'
