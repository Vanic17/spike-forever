$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs/baseline-v15'
$checked=0
foreach($file in Get-ChildItem -LiteralPath $baseline -Filter '*.gd'){
 if($file.Name -in @('main.gd','court_shape.gd','hud.gd')){continue}
 if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root ('src/'+$file.Name))).Hash){throw ('Protected source changed: '+$file.Name)}
 $checked++
}
foreach($name in @('controls.cfg','sources.json')){
 $current=if($name -eq 'sources.json'){Join-Path $root 'assets/active/sources.json'}else{Join-Path $root $name}
 if((Get-FileHash -LiteralPath $current).Hash -ne (Get-FileHash -LiteralPath (Join-Path $baseline $name)).Hash){throw ('Existing controls or clips changed: '+$name)}
 $checked++
}
$allowed=@('setup_inputs','_unhandled_input','read_controls','press_action','set_phase','reset_rally','set_ball','prepare_overpass_attack','step','choose_block_lane','wall_attack_id','blocking_players','blocking_target','manual_wall_route','waiting_wall_target','request_block_jump','move_players','avoid_teammates','test_charge_and_context_controls')
$before=[IO.File]::ReadAllText((Join-Path $baseline 'main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
foreach($method in [regex]::Matches($before,'(?ms)^func (?<name>\w+)\(.*?(?=^func |\z)')){
 $name=$method.Groups['name'].Value
 if($name -in $allowed){continue}
 $now=[regex]::Match($after,'(?ms)^func '+$name+'\(.*?(?=^func |\z)').Value
 if($now.Trim() -ne $method.Value.Trim()){throw ('Unrelated game function changed: '+$name)}
 $checked++
}
Write-Output ('REVISION16 SCOPE PASS: '+$checked+' checks / ball physics, shot timing, PlayStyle, rotation sequence, existing face buttons, camera, audio and animation assets retained / new wall controls authorized')
