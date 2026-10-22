$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs/baseline-v16'
$checked=0
foreach($file in Get-ChildItem -LiteralPath $baseline -Filter '*.gd'){
 if($file.Name -in @('main.gd','avatar.gd')){continue}
 if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root ('src/'+$file.Name))).Hash){throw ('Protected source changed: '+$file.Name)}
 $checked++
}
foreach($name in @('controls.cfg','sources.json')){
 $current=if($name -eq 'sources.json'){Join-Path $root 'assets/active/sources.json'}else{Join-Path $root $name}
 if((Get-FileHash -LiteralPath $current).Hash -ne (Get-FileHash -LiteralPath (Join-Path $baseline $name)).Hash){throw ('Controls or PSA sources changed: '+$name)}
 $checked++
}
foreach($filename in @('main.gd','avatar.gd')){
 $before=[IO.File]::ReadAllText((Join-Path $baseline $filename))
 $after=[IO.File]::ReadAllText((Join-Path $root ('src/'+$filename)))
 $allowed=if($filename -eq 'main.gd'){@('_unhandled_input')}else{@('setup','apply_pose','normalized_pose','layer_legs','blend_hierarchy')}
 foreach($method in [regex]::Matches($before,'(?ms)^func (?<name>\w+)\(.*?(?=^func |\z)')){
  $name=$method.Groups['name'].Value
  if($name -in $allowed){continue}
  $now=[regex]::Match($after,'(?ms)^func '+$name+'\(.*?(?=^func |\z)').Value
  if($now.Trim() -ne $method.Value.Trim()){throw ('Unrelated function changed: '+$filename+':'+$name)}
  $checked++
 }
}
# The only input addition is the comparison key. Preserve every existing branch.
$before=[IO.File]::ReadAllText((Join-Path $baseline 'main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
$after=[regex]::Replace($after,'(?m)^\t{3}KEY_F6:\r?\n(?:\t{4}[^\r\n]*\r?\n)+','')
if($after.Trim() -ne $before.Trim()){throw 'Main differs beyond the animation comparison key'}
$oldAvatar=[IO.File]::ReadAllText((Join-Path $baseline 'avatar.gd'))
$newAvatar=[IO.File]::ReadAllText((Join-Path $root 'src/avatar.gd'))
$oldSampler=[regex]::Match($oldAvatar,'(?ms)^func normalized_pose\(.*?(?=^func |\z)').Value.Trim()
$newSampler=[regex]::Match($newAvatar,'(?ms)^func psa_normalized_pose\(.*?(?=^func |\z)').Value.Trim().Replace('func psa_normalized_pose(', 'func normalized_pose(')
if($oldSampler -ne $newSampler){throw 'Fallback normalization changed'}
$corrections='(?ms)^\tif _dt > 0:\r?\n\t\tif looping:.*?^\tlast_pose = normalized'
if([regex]::Match($oldAvatar,$corrections).Value -ne [regex]::Match($newAvatar,$corrections).Value){throw 'Procedural feet, head or contact corrections changed'}
$checked+=2
Write-Output ('NATIVE ANIMATION SCOPE PASS: '+$checked+' checks / gameplay, controls, movement, ball, tactics, parser, assets and procedural corrections retained')
