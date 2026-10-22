$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$checks=0
foreach($name in @('main.gd','timing.gd','reference_style.gd')){
 $old=[IO.File]::ReadAllText((Join-Path $root ('docs/baseline-v21/'+$name)))
 $new=[IO.File]::ReadAllText((Join-Path $root ('src/'+$name)))
 foreach($match in [regex]::Matches($old,'(?ms)^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\z)')){
  $method=$match.Groups[1].Value
  if(($name -eq 'main.gd' -and $method -in @('serve_ball','read_controls')) -or ($name -eq 'reference_style.gd' -and $method -eq 'serve_seconds')){continue}
  $pattern='(?ms)^(?:static )?func '+$method+'\(.*?(?=^(?:static )?func |\z)'
  if($match.Value.Trim() -ne [regex]::Match($new,$pattern).Value.Trim()){throw ('Unexpected gameplay change: '+$name+':'+$method)}
  $checks++
 }
 if($name -eq 'timing.gd'){
  if($old.Replace('SERVE_CHARGE_SECONDS := 1.05','SERVE_CHARGE_SECONDS := 0.78').Trim() -ne $new.Trim()){throw 'Only serve charge duration may change in timing.gd'}
 }
}
foreach($name in @('ball_flight.gd','ball_contact.gd','psa.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Protected module changed: '+$name)}
 $checks++
}
if((Get-FileHash (Join-Path $root 'src/avatar.gd')).Hash -ne (Get-FileHash (Join-Path $root 'docs/baseline-v19/avatar.gd')).Hash){throw 'Animation backend changed'}
Write-Output ('REVISION22 SCOPE PASS: '+($checks+1)+' checks / non-serve ball physics, attack timing, scoring, rotation lifecycle, controls and animation backend retained')
