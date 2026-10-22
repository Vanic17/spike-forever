$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$checks=0
foreach($module in @('main.gd','rally_ai.gd','reference_style.gd','setter_access.gd')){
 $allowed=switch($module){'main.gd'{@('press_action','receive_ball','serve_aim_target','test_manual_reception')};'rally_ai.gd'{@('opening')};'reference_style.gd'{@('serve_seconds','set_seconds')};'setter_access.gd'{@('clear_target')}}
 $old=[IO.File]::ReadAllText((Join-Path $root ('docs/baseline-v24/'+$module)))
 $new=[IO.File]::ReadAllText((Join-Path $root ('src/'+$module)))
 foreach($m in [regex]::Matches($old,'(?ms)^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\z)')){
  $name=$m.Groups[1].Value
  if($name -in $allowed){continue}
  if($m.Value.Trim() -ne [regex]::Match($new,('(?ms)^(?:static )?func '+$name+'\(.*?(?=^(?:static )?func |\z)')).Value.Trim()){throw ('Unexpected change: '+$module+':'+$name)}
  $checks++
 }
}
$old=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v24/timing.gd')).Replace('SERVE_CHARGE_SECONDS := 0.74','SERVE_CHARGE_SECONDS := 0.70')
if($old.Trim() -ne [IO.File]::ReadAllText((Join-Path $root 'src/timing.gd')).Trim()){throw 'Unexpected timing change'}
foreach($module in @('avatar.gd','psa.gd','pose_animation_tree.gd','ball_flight.gd','ball_contact.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$module))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v23/'+$module))).Hash){throw ('Protected module changed: '+$module)}
 $checks++
}
Write-Output ('REVISION25 SCOPE PASS: '+$checks+' checks / rotation, input bindings, ball integrator, animation backend and attack retained / setter contact and requested tempos allowed')