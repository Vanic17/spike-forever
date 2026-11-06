$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/legend75-validation80-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/legend75-validation80-local'
foreach($test in @('Test-Defense80','Test-DefensePoses80','Test-Attack80','Test-LegendInputs75','Test-LegendReception76','Test-LegendSetter79','Test-LegendServe79','Test-SecondSpike79','Test-Defense77','Test-Attack78','Benchmark-Defense80')){
 $stdout=Join-Path $root ('.runtime/'+$test+'-final80.stdout.log')
 $stderr=Join-Path $root ('.runtime/'+$test+'-final80.stderr.log')
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList @('--headless','--path','.','--script',('tools/'+$test+'.gd')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
 if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw ('Timeout '+$test)}
 $p.Refresh()
 if((Get-Content -Raw $stderr) -match 'SCRIPT ERROR|Parse Error|Assertion failed' -or (Get-Content -Raw $stdout) -notmatch 'PASS|"pass":true'){throw ('Failed '+$test+' exit '+$p.ExitCode)}
 Write-Output ('PASS '+$test)
}
