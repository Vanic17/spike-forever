param([switch]$SkipCompletedPresetLifecycle)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/graphics89-final-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/graphics89-final-local'
function Run-Rendered89($name89,$arguments89,$timeout89=90000){
 $out89='.runtime/graphics89-final-'+$name89+'.stdout.log'
 $err89='.runtime/graphics89-final-'+$name89+'.stderr.log'
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments89 -WindowStyle Hidden -PassThru -RedirectStandardOutput $out89 -RedirectStandardError $err89
 $handle89=$p.Handle
 if(!$p.WaitForExit($timeout89)){Stop-Process -Id $p.Id;throw ('Timeout '+$name89)}
 $errors89=(Get-Content -Raw $err89) -replace '(?m)^ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates[^\r\n]*\r?\n?',''
 if($p.ExitCode -ne 0 -or $errors89 -match 'ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error|remapped parameter not found' -or (Get-Content -Raw $out89) -notmatch 'PASS'){throw ('Failed '+$name89+'; inspect '+$err89)}
 Write-Output ('PASS '+$name89)
}
if(!$SkipCompletedPresetLifecycle){
 Run-Rendered89 'presets' @('--path','.','--script','tools/Test-Graphics89.gd')
 Run-Rendered89 'lifecycle' @('--path','.','--script','tools/Test-GraphicsLifecycle89.gd')
}
Run-Rendered89 'capture' @('--path','.','--script','tools/Capture-Graphics89.gd','--','--label=after')
foreach($preset89 in 0..3){
 $runs89=if($preset89 -eq 2){1..3}else{1..1}
 foreach($run89 in $runs89){
  Run-Rendered89 ('benchmark-'+$preset89+'-'+$run89) @('--path','.','--script','tools/Benchmark-Graphics89.gd','--',('--label=p'+$preset89+'-r'+$run89),('--preset='+$preset89))
 }
}
Run-Rendered89 'fullmatch' @('--path','.','--script','tools/Stability-Graphics89.gd','--','--maximum-attacks') 330000
