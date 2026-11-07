$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$engine=Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.runtime/graphics85-final-render-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/graphics85-final-render-local'
foreach($preset85 in 0..3){
 $label85='after-'+@('low','medium','high','ultra')[$preset85]
 $output85='.runtime/graphics85-'+$label85+'-final.stdout.log'
 $error85='.runtime/graphics85-'+$label85+'-final.stderr.log'
 $p=Start-Process $engine -ArgumentList @('--path','.','--script','tools/Benchmark-Graphics85.gd','--',('--label='+$label85),('--preset='+$preset85)) -WindowStyle Hidden -PassThru -RedirectStandardOutput $output85 -RedirectStandardError $error85
 if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw ('Render timeout '+$label85)}
 if((Get-Content -Raw $output85) -notmatch 'GRAPHICS85 BENCH PASS' -or (Get-Content -Raw $error85) -match 'SHADER ERROR|SCRIPT ERROR|Parse Error'){throw ('Render failed '+$label85)}
 Write-Output ('PASS renderer '+$label85)
}
$p=Start-Process $engine -ArgumentList @('--path','.','--script','tools/Capture-Graphics85.gd','--','--label=after') -WindowStyle Hidden -PassThru -RedirectStandardOutput '.runtime/graphics85-after.stdout.log' -RedirectStandardError '.runtime/graphics85-after.stderr.log'
if(!$p.WaitForExit(90000)){Stop-Process -Id $p.Id;throw 'Capture timeout'}
if((Get-Content -Raw '.runtime/graphics85-after.stderr.log') -match 'SHADER ERROR|SCRIPT ERROR|Parse Error'){throw 'Capture failed'}
Write-Output 'PASS five final captures'
