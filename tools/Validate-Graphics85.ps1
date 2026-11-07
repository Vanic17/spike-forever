$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/legend75-settings53-career66-graphics85-regressions-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/legend75-settings53-career66-graphics85-regressions-local'
foreach($test in @('Test-Graphics85','Test-Settings53','Test-ControllerSettings53','Test-Fluidity84','Test-SetterPose81','Test-Setter81','Test-LegendInputs75','Test-LegendServe81','Test-Attack80','Test-Defense80','Test-Arena82','Test-Arenas70','Test-Kits45','Test-Replay65','Test-ReplayEvents65','Test-Bench71','Test-CareerPlayed66','Test-CareerEngine66')){
 $stdout=Join-Path $root ('.runtime/'+$test+'-graphics85.stdout.log')
 $stderr=Join-Path $root ('.runtime/'+$test+'-graphics85.stderr.log')
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList @('--headless','--path','.','--script',('tools/'+$test+'.gd')) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
 if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw ('Timeout '+$test)}
 if((Get-Content -Raw $stderr) -match 'SCRIPT ERROR|Parse Error|Assertion failed|LEGEND INPUT75:|SHADER ERROR' -or (Get-Content -Raw $stdout) -notmatch 'PASS'){throw ('Failed '+$test)}
 Write-Output ('PASS '+$test)
}
