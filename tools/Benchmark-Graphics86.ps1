param([ValidateSet('before','after')][string]$Stage='after',[int]$Runs=3)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$project86=$root
if($Stage -eq 'before'){$project86=Join-Path $root 'dist/source-0.85.0-004f633cf8f1489d88b1f0a260bbee38'}
$env:APPDATA=Join-Path $root ('.runtime/graphics86-bench-'+$Stage+'-appdata')
$env:LOCALAPPDATA=Join-Path $root ('.runtime/graphics86-bench-'+$Stage+'-local')
for($run86=1;$run86 -le $Runs;$run86++){
 $label86='86-'+$Stage+'-high-r'+$run86
 $stdout86=Join-Path $root ('.runtime/graphics86-'+$Stage+'-r'+$run86+'.stdout.log')
 $stderr86=Join-Path $root ('.runtime/graphics86-'+$Stage+'-r'+$run86+'.stderr.log')
 $p=Start-Process (Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe') -ArgumentList @('--path',('"'+$project86+'"'),'--script','tools/Benchmark-Graphics85.gd','--',('--label='+$label86),'--preset=2') -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout86 -RedirectStandardError $stderr86
 $handle86=$p.Handle
 if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw 'Benchmark timeout'}
 if($p.ExitCode -ne 0 -or (Get-Content -Raw $stdout86) -notmatch 'GRAPHICS85 BENCH PASS' -or (Get-Content -Raw $stderr86) -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|CrashHandlerException'){throw ('Benchmark failed '+$label86)}
 Copy-Item -LiteralPath (Join-Path $project86 ('docs/graphics85-performance-'+$label86+'.json')) -Destination (Join-Path $root ('docs/graphics86-performance-'+$Stage+'-high-r'+$run86+'.json'))
 Write-Output ('PASS '+$label86)
}
