$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs/baseline-v14'
$allowed=@('avatar.gd','main.gd','psa.gd','court_shape.gd')
$checked=0
foreach($file in Get-ChildItem -LiteralPath $baseline -Filter '*.gd'){
 if($file.Name -in $allowed){continue}
 if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root ('src/'+$file.Name))).Hash){throw ('Protected v14 source changed: '+$file.Name)}
 $checked++
}
if((Get-FileHash -LiteralPath (Join-Path $baseline 'controls.cfg')).Hash -ne (Get-FileHash -LiteralPath (Join-Path $root 'controls.cfg')).Hash){throw 'Controller bindings changed'}
$pattern='(?ms)^func (?<name>\w+)\(.*?(?=^func |\z)'
$before=[IO.File]::ReadAllText((Join-Path $baseline 'main.gd'))
$after=[IO.File]::ReadAllText((Join-Path $root 'src/main.gd'))
foreach($method in [regex]::Matches($before,$pattern)){
 $name=$method.Groups['name'].Value
 if($name -in @('_ready','move_players','run_tests')){continue}
 $current=[regex]::Match($after,'(?ms)^func '+$name+'\(.*?(?=^func |\z)').Value
 if($current.Trim() -ne $method.Value.Trim()){throw ('Game function changed outside motion scope: '+$name)}
 $checked++
}
$old=Get-Content -LiteralPath (Join-Path $baseline 'sources.json') -Raw | ConvertFrom-Json
$new=Get-Content -LiteralPath (Join-Path $root 'assets/active/sources.json') -Raw | ConvertFrom-Json
foreach($entry in $old.PSObject.Properties){if($new.($entry.Name) -ne $entry.Value){throw ('Existing animation replaced: '+$entry.Name)}}
Write-Output ('FLUIDITY SCOPE PASS: '+$checked+' checks / v14 rules, rotations, controls, timing, PlayStyle, ball physics and game decisions unchanged')
