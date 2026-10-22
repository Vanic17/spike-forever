$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs\baseline-v08'
$checked=0
foreach($name in @('controls.cfg','arena.gd','crowd.gd','source_assets.gd','match_audio.gd')){
 $current=if($name.EndsWith('.cfg')){Join-Path $root $name}else{Join-Path $root ('src\'+$name)}
 if((Get-FileHash -LiteralPath $current).Hash -ne (Get-FileHash -LiteralPath (Join-Path $baseline $name)).Hash){throw ('Protected appearance/input file changed: '+$name)}
 $checked++
}
foreach($entry in @(@('main.gd','set_camera'),@('main.gd','update_camera'),@('main.gd','release_action'),@('main.gd','current_charge'),@('avatar.gd','setup_meshes'),@('hud.gd','panel'),@('hud.gd','text'))){
 $filename=$entry[0];$method=$entry[1]
 $current=[IO.File]::ReadAllText((Join-Path $root ('src\'+$filename)),[Text.Encoding]::UTF8)
 $old=[IO.File]::ReadAllText((Join-Path $baseline $filename),[Text.Encoding]::UTF8)
 $pattern='(?ms)^func '+[regex]::Escape($method)+'\(.*?(?=^func |\z)'
 $actual=[regex]::Match($current,$pattern).Value.Trim()
 $expected=[regex]::Match($old,$pattern).Value.Trim()
 if(!$actual -or $actual -ne $expected){throw ('Protected function changed: '+$filename+':'+$method)}
 $checked++
}
$main=[IO.File]::ReadAllText((Join-Path $root 'src\main.gd'),[Text.Encoding]::UTF8)
$controls=[regex]::Match($main,'(?ms)^func read_controls\(.*?(?=^func |\z)').Value
$movement=[regex]::Match($main,'(?ms)^func move_players\(.*?(?=^func |\z)').Value
if($controls -notmatch 'stick\((?:false)?\)' -or $controls -match 'stick\(true\)' -or $main -match 'JOY_AXIS_RIGHT_[XY]'){throw 'Aim and tactical choices must use the left stick'}
if($movement -match 'stick\('){throw 'Manual player movement must not consume the aiming stick'}
$checked+=2
Write-Output ('REFERENCE SCOPE PASS: '+$checked+' checks / camera, graphical assets, sound, face buttons and charge controls retained / left-stick aim without manual movement')
