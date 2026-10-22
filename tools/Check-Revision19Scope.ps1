$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$before=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v18/main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$checks=0
foreach($name in @('setup_inputs','press_action','release_action','read_controls','current_charge','launch','serve_ball','receive_ball','attack_ball','award','validate_contact','queue_recovery','request_block_jump','step','step_dead_ball','advance_dive_body')){
 $pattern='(?ms)^func '+$name+'\(.*?(?=^func |\z)'
 if([regex]::Match($before,$pattern).Value.Trim() -ne [regex]::Match($after,$pattern).Value.Trim()){throw ('Protected gameplay changed: '+$name)}
 $checks++
}
foreach($name in @('timing.gd','ball_flight.gd','ball_contact.gd','psa.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Protected module changed: '+$name)}
 $checks++
}
Write-Output ('REVISION19 SCOPE PASS: '+$checks+' checks / physics, scoring, timing and input controls retained; role labels, serving positions, defensive flank planning and update menu authorized')
