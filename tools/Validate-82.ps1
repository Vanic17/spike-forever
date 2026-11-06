$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/legend75-validation82-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/legend75-validation82-local'
foreach($test in @('Test-Codes82','Test-Arena82','Test-Arenas70','Test-Arena61','Test-LegendInputs75','Test-LegendServe81','Test-Setter81','Test-Attack80','Test-Defense80')){
 $stdout=Join-Path $root ('.runtime/'+$test+'-final82.stdout.log')
 $stderr=Join-Path $root ('.runtime/'+$test+'-final82.stderr.log')
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList @('--headless','--path','.','--script',('tools/'+$test+'.gd')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
 if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw ('Timeout '+$test)}
 if((Get-Content -Raw $stderr) -match 'SCRIPT ERROR|Parse Error|Assertion failed' -or (Get-Content -Raw $stdout) -notmatch 'PASS'){throw ('Failed '+$test)}
 Write-Output ('PASS '+$test)
}
