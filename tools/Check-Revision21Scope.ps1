$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$before=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v20/main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$checks=0
foreach($name in @('setup_inputs','press_action','release_action','read_controls','current_charge','launch','serve_ball','receive_ball','set_ball','attack_ball','award','validate_contact','queue_recovery','request_block_jump','step','step_dead_ball','advance_dive_body')){
 $pattern='(?ms)^func '+$name+'\(.*?(?=^func |\z)'
 $old=[regex]::Match($before,$pattern).Value.Trim()
 $new=[regex]::Match($after,$pattern).Value.Trim()
 if($name -eq 'setup_inputs'){$new=[regex]::Replace($new,'(?ms)\r?\n\t\tvar axis:=InputEventJoypadMotion.new\(\).*?(?=\r?\n\tfor binding in)','')}
 if($name -eq 'set_ball'){
  $line=[regex]::Match($old,'(?m)^\tvar approach_time :=.*$').Value
  $new=[regex]::Replace($new,'(?m)^\tvar approach_time :=.*$',[System.Text.RegularExpressions.MatchEvaluator]{param($m) $line})
 }
 if($old -ne $new){throw ('Protected gameplay changed: '+$name)}
 $checks++
}
foreach($name in @('timing.gd','ball_flight.gd','ball_contact.gd','psa.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Protected module changed: '+$name)}
 $checks++
}
if((Get-FileHash (Join-Path $root 'src/avatar.gd')).Hash -ne (Get-FileHash (Join-Path $root 'docs/baseline-v19/avatar.gd')).Hash){throw 'Animation backend changed'}
Write-Output ('REVISION21 SCOPE PASS: '+($checks+1)+' checks / charge, ball model, scoring, rotation and animation retained; arrival floor and LS action bindings explicitly allowed')
