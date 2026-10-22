$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$before=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v19/main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$checks=0
foreach($name in @('setup_inputs','press_action','release_action','read_controls','current_charge','launch','serve_ball','receive_ball','attack_ball','award','validate_contact','queue_recovery','request_block_jump','step','step_dead_ball','advance_dive_body')){
 $pattern='(?ms)^func '+$name+'\(.*?(?=^func |\z)'
 $old=[regex]::Match($before,$pattern).Value.Trim()
 $new=[regex]::Match($after,$pattern).Value.Trim()
 if($name -eq 'serve_ball'){
  $new=[regex]::Replace($new,'(?ms)\n\tvar layout: Dictionary=rotation_context.capture\(self,team\).*?(?=\n\tlast_touch = team)','')
  $new=[regex]::Replace($new,'\n\tif not layout.legal:\r?\n\t\taward\(team,"FALLO DI POSIZIONE IN RICEZIONE"\)\r?\n\t\treturn','')
 }
 if($old -ne $new){throw ('Protected gameplay changed: '+$name)}
 $checks++
}
foreach($name in @('timing.gd','ball_flight.gd','ball_contact.gd','psa.gd','arena.gd','match_audio.gd','avatar.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash -and $name -ne 'avatar.gd'){throw ('Protected module changed: '+$name)}
 if($name -eq 'avatar.gd' -and (Get-FileHash (Join-Path $root 'src/avatar.gd')).Hash -ne (Get-FileHash (Join-Path $root 'docs/baseline-v19/avatar.gd')).Hash){throw 'Animation backend changed'}
 $checks++
}
Write-Output ('REVISION20 SCOPE PASS: '+$checks+' checks / input, charge, physics, scoring and animation backend retained; explicit service-position validation added')
