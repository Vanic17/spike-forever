$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs\baseline-v10'
$checked=0
foreach($name in @('controls.cfg','timing.gd','ball_flight.gd','reference_style.gd','arena.gd','match_audio.gd')){
 $current=if($name.EndsWith('.cfg')){Join-Path $root $name}else{Join-Path $root ('src\'+$name)}
 if((Get-FileHash -LiteralPath $current).Hash -ne (Get-FileHash -LiteralPath (Join-Path $baseline $name)).Hash){throw ('Revision 11 changed a protected gameplay/appearance source: '+$name)}
 $checked++
}
$oldSources=Get-Content -LiteralPath (Join-Path $baseline 'sources.json') -Raw | ConvertFrom-Json
$newSources=Get-Content -LiteralPath (Join-Path $root 'assets\active\sources.json') -Raw | ConvertFrom-Json
foreach($property in $oldSources.PSObject.Properties){
 if($newSources.($property.Name) -ne $property.Value){throw ('An existing source animation was replaced: '+$property.Name)}
}
foreach($property in $newSources.PSObject.Properties){
 $active=Join-Path $root ('assets\active\'+$property.Name+'.psa')
 $original=Join-Path $root ('assets\spike\Game\CharactersV1\Animations\'+$property.Value)
 $expected=if(Test-Path -LiteralPath $original){(Get-FileHash -LiteralPath $original).Hash}else{(Get-Content -Raw (Join-Path $root 'docs/original-animation-hashes.json') | ConvertFrom-Json).($property.Name)}
 if(!$expected -or (Get-FileHash -LiteralPath $active).Hash -ne $expected){throw ('Animation differs from its declared original: '+$property.Name)}
}
if((Get-FileHash -LiteralPath (Join-Path $root 'assets\gameplay\killer_aces_reference.json')).Hash -ne (Get-FileHash -LiteralPath (Join-Path $baseline 'killer_aces_reference.json')).Hash){throw 'The old reference tuning changed'}
$checked+=2
foreach($entry in @(@('main.gd','release_action'),@('main.gd','current_charge'),@('main.gd','attack_ball'),@('main.gd','launch'),@('main.gd','award'),@('rally_ai.gd','reception_quality'),@('rally_ai.gd','system_quality'),@('rally_ai.gd','attack_choice'),@('psa.gd','load_file'),@('psa.gd','pose'),@('psa.gd','root_motion'))){
 $filename=$entry[0]; $method=$entry[1]
 $current=[IO.File]::ReadAllText((Join-Path $root ('src\'+$filename)),[Text.Encoding]::UTF8)
 $old=[IO.File]::ReadAllText((Join-Path $baseline $filename),[Text.Encoding]::UTF8)
 $pattern='(?ms)^(?:static )?func '+[regex]::Escape($method)+'\(.*?(?=^(?:static )?func |\z)'
 if([regex]::Match($current,$pattern).Value.Trim() -ne [regex]::Match($old,$pattern).Value.Trim()){throw ('Gameplay function changed beyond positioning: '+$filename+':'+$method)}
 $checked++
}
Write-Output ('POSITION SCOPE PASS: '+$checked+' checks / controls, rally physics and timing retained / original animation files plus authorised contextual variants')
