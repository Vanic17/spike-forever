$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs/baseline-v17_1'
foreach($name in @('controls.cfg','sources.json')){
 $current=if($name -eq 'sources.json'){Join-Path $root 'assets/active/sources.json'}else{Join-Path $root $name}
 if((Get-FileHash $current).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Controls/assets changed: '+$name)}
}
$before=[IO.File]::ReadAllText((Join-Path $baseline 'main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$allowed=@('move_players','choose_cpu_play','plan_attack','set_ball','collision_safe_step','footprint_points','avoid_teammates','test_planned_attacks_and_jump_lifecycle')
$checked=2
foreach($method in [regex]::Matches($before,'(?ms)^func (?<name>\w+)\(.*?(?=^func |\z)')){
 $name=$method.Groups['name'].Value
 if($name -in $allowed){continue}
 $actual=[regex]::Match($after,'(?ms)^func '+$name+'\(.*?(?=^func |\z)').Value
 if($actual.Trim() -ne $method.Value.Trim()){throw ('Unrelated main function changed: '+$name)}
 $checked++
}
foreach($name in @('timing.gd','ball_flight.gd','ball_contact.gd','psa.gd','manual_wall.gd','arena.gd','match_audio.gd','reference_style.gd')){
 if((Get-FileHash (Join-Path $root ('src/'+$name))).Hash -ne (Get-FileHash (Join-Path $root ('docs/baseline-v16/'+$name))).Hash){throw ('Protected module changed: '+$name)}
 $checked++
}
$setPattern='(?ms)^func set_ball\(.*?(?=^func |\z)'
$oldSet=[regex]::Match($before,$setPattern).Value
$newSet=[regex]::Match($after,$setPattern).Value
$noticePattern='(?m)^\tnotice\(\("#%d.*$'
if([regex]::Replace($oldSet,$noticePattern,'') -ne [regex]::Replace($newSet,$noticePattern,'')){throw 'Set contact, flight or timing changed beyond lane label'}
$oldAI=[IO.File]::ReadAllText((Join-Path $baseline 'rally_ai.gd'))
$newAI=[IO.File]::ReadAllText((Join-Path $root 'src/rally_ai.gd'))
foreach($name in @('reception_quality','system_quality','attack_choice')){
 $pattern='(?ms)^static func '+$name+'\(.*?(?=^static func |\z)'
 if([regex]::Match($oldAI,$pattern).Value.Trim() -ne [regex]::Match($newAI,$pattern).Value.Trim()){throw ('Rally quality/timing changed: '+$name)}
 $checked++
}
$oldTactics=[IO.File]::ReadAllText((Join-Path $baseline 'tactics.gd'))
$newTactics=[IO.File]::ReadAllText((Join-Path $root 'src/tactics.gd'))
foreach($name in @('ROLES','INITIAL_SLOTS','ZONES')){
 $pattern='(?m)^const '+$name+' := .*'
 if([regex]::Match($oldTactics,$pattern).Value -ne [regex]::Match($newTactics,$pattern).Value){throw ('Roster/rotation order changed: '+$name)}
 $checked++
}
Write-Output ('REVISION18 SCOPE PASS: '+$checked+' checks / controls, ball physics, timing, scoring, rotation sequence, manual wall and quality decisions preserved; first-ball lanes, recovery traffic and full animation migration authorized')
