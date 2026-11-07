$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/athlete87-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/athlete87-local'
function Run-AthleteCase87($name87,$arguments87){
 $out87='.runtime/athlete87-approved-'+$name87+'.stdout.log'
 $err87='.runtime/athlete87-approved-'+$name87+'.stderr.log'
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments87 -WindowStyle Hidden -PassThru -RedirectStandardOutput $out87 -RedirectStandardError $err87
 $handle87=$p.Handle
 if(!$p.WaitForExit(120000)){Stop-Process -Id $p.Id;throw ('Timeout '+$name87)}
 $errors87=(Get-Content -Raw $err87) -replace '(?m)^ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates[^\r\n]*\r?\n?',''
 if($p.ExitCode -ne 0 -or $errors87 -match 'ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error|remapped parameter not found' -or (Get-Content -Raw $out87) -notmatch 'PASS'){throw ('Failed '+$name87+'; inspect '+$err87)}
 Write-Output ('PASS '+$name87)
}
Run-AthleteCase87 'skin-tests' @('--headless','--path','.','--script','tools/Test-Athlete87.gd','--','--athlete-prototype87')
Run-AthleteCase87 'lifecycle' @('--path','.','--script','tools/Test-AthleteLifecycle87.gd','--','--athlete-prototype87')
foreach($side87 in @('before','after')){
 $args87=@('--path','.','--script','tools/Capture-Athlete87.gd','--',('--label='+$side87))
 if($side87 -eq 'after'){$args87+='--athlete-prototype87'}
 Run-AthleteCase87 ('capture-'+$side87) $args87
}
foreach($run87 in 1..3){
 Run-AthleteCase87 ('benchmark-after-r'+$run87) @('--path','.','--script','tools/Benchmark-Athlete87.gd','--',('--label=after-r'+$run87),'--preset=2','--athlete-prototype87')
}
tools/python311/python.exe tools/Build-AthleteReview87.py
