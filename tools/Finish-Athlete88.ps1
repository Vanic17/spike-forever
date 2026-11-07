$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$env:APPDATA=Join-Path $root '.runtime/athlete88-appdata'
$env:LOCALAPPDATA=Join-Path $root '.runtime/athlete88-local'
function Run-Case88($name88,$arguments88){
 $out88='.runtime/athlete88-final-'+$name88+'.stdout.log'
 $err88='.runtime/athlete88-final-'+$name88+'.stderr.log'
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments88 -WindowStyle Hidden -PassThru -RedirectStandardOutput $out88 -RedirectStandardError $err88
 $handle88=$p.Handle
 if(!$p.WaitForExit(150000)){Stop-Process -Id $p.Id;throw ('Timeout '+$name88)}
 $errors88=(Get-Content -Raw $err88) -replace '(?m)^ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates[^\r\n]*\r?\n?',''
 if($p.ExitCode -ne 0 -or $errors88 -match 'ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error|remapped parameter not found' -or (Get-Content -Raw $out88) -notmatch 'PASS'){throw ('Failed '+$name88+'; inspect '+$err88)}
 Write-Output ('PASS '+$name88)
}
Run-Case88 'skin-tests' @('--headless','--path','.','--script','tools/Test-Athlete88.gd','--','--athlete-prototype87','--athlete-next88')
Run-Case88 'lifecycle' @('--path','.','--script','tools/Test-AthleteLifecycle88.gd','--','--athlete-prototype87','--athlete-next88')
foreach($side88 in @('before','after')){
 $args88=@('--path','.','--script','tools/Capture-Athlete88.gd','--',('--label='+$side88),'--athlete-prototype87')
 if($side88 -eq 'after'){$args88+='--athlete-next88'}
 Run-Case88 ('capture-'+$side88) $args88
}
tools/python311/python.exe tools/Build-AthleteReview88.py
if($LASTEXITCODE -ne 0){throw 'Review invariant validation failed'}
