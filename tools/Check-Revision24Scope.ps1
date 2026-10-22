$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$checks=0
$allowed=@('_ready','reset_rally','choose_cpu_play','plan_attack','select_receive_pose','run_tests','test_planned_attacks_and_jump_lifecycle')
$before=[IO.File]::ReadAllText((Join-Path $root 'docs/baseline-v23/main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
foreach($match in [regex]::Matches($before,'(?ms)^func (\w+)\(.*?(?=^func |\z)')){
 $name=$match.Groups[1].Value
 if($name -in $allowed){continue}
 if($match.Value.Trim() -ne [regex]::Match($after,('(?ms)^func '+$name+'\(.*?(?=^func |\z)')).Value.Trim()){throw ('Unexpected gameplay change: '+$name)}
 $checks++
}
foreach($module in @('rally_ai.gd','reference_style.gd','psa_animation_library.gd')){
 $allowedMethods=switch($module){'rally_ai.gd'{@('defensive_base','opening','coverage')};'reference_style.gd'{@('attack_seconds')};default{@()}}
 $old=[IO.File]::ReadAllText((Join-Path $root ('docs/baseline-v23/'+$module)))
 if($module -eq 'psa_animation_library.gd'){$old=$old.Replace('all 33 libraries','all native clips')}
 $new=[IO.File]::ReadAllText((Join-Path $root ('src/'+$module)))
 foreach($match in [regex]::Matches($old,'(?ms)^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\z)')){
  $method=$match.Groups[1].Value
  if($method -in $allowedMethods){continue}
  $pattern='(?ms)^(?:static )?func '+$method+'\(.*?(?=^(?:static )?func |\z)'
  if($match.Value.Trim() -ne [regex]::Match($new,$pattern).Value.Trim()){throw ('Unexpected change: '+$module+':'+$method)}
  $checks++
 }
}
foreach($module in @('avatar.gd','psa.gd','pose_animation_tree.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$module))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v23/'+$module))).Hash){throw ('Existing animation engine changed: '+$module)}
 $checks++
}
foreach($module in @('timing.gd','ball_flight.gd','ball_contact.gd','arena.gd','match_audio.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$module))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v23/'+$module))).Hash){throw ('Protected module changed: '+$module)}
 $checks++
}
Write-Output ('REVISION24 SCOPE PASS: '+$checks+' checks / charge, serve, input, camera, scoring, rotation slots, ball integrator, PSA and AnimationTree backend retained; committed pin lanes, 15 distinct clips and strong spikes allowed')
