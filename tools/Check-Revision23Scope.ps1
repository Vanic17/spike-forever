$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$before=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v22/main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$allowed=@('set_camera','update_camera','_unhandled_input','read_controls','receive_ball','move_players','serve_aim_target')
$checks=0
foreach($match in [regex]::Matches($before,'(?ms)^func (\w+)\(.*?(?=^func |\z)')){
 $name=$match.Groups[1].Value
 if($name -in $allowed){continue}
 $pattern='(?ms)^func '+$name+'\(.*?(?=^func |\z)'
 if($match.Value.Trim() -ne [regex]::Match($after,$pattern).Value.Trim()){throw ('Unexpected gameplay change: '+$name)}
 $checks++
}
foreach($name in @('timing.gd','reference_style.gd')){
 $old=[IO.File]::ReadAllText((Join-Path $root ('docs/baseline-v22/'+$name)))
 $new=[IO.File]::ReadAllText((Join-Path $root ('src/'+$name)))
 if($name -eq 'timing.gd'){$old=$old.Replace('SERVE_CHARGE_SECONDS := 0.78','SERVE_CHARGE_SECONDS := 0.74')}
 else{$old=$old.Replace('1.00 if floating else 0.82','0.96 if floating else 0.79')}
 if($old.Trim() -ne $new.Trim()){throw ('Only requested serve tuning may change: '+$name)}
 $checks++
}
foreach($name in @('ball_flight.gd','ball_contact.gd','psa.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Protected module changed: '+$name)}
 $checks++
}
if((Get-FileHash (Join-Path $root 'src/avatar.gd')).Hash -ne (Get-FileHash (Join-Path $root 'docs/baseline-v19/avatar.gd')).Hash){throw 'Animation backend changed'}
Write-Output ('REVISION23 SCOPE PASS: '+($checks+1)+' checks / ball integrator, scoring, rotation, attack timing and animation backend retained / camera mapping, setter access and wall routes explicitly allowed')
