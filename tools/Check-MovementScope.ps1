$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$expected=Get-Content -Raw (Join-Path $root 'docs\motion-scope-before.json') | ConvertFrom-Json
$source=Get-Content -Raw (Join-Path $root 'src\main.gd')
$functions=@{}
foreach($part in [regex]::Matches($source,'(?ms)^func ([A-Za-z_0-9]+)\(.*?(?=^func |\z)')){
 $sha=[Security.Cryptography.SHA256]::Create()
 $functions[$part.Groups[1].Value]=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($part.Value))).Replace('-','')
}
$checked=0
foreach($item in $expected.PSObject.Properties){
 $actual=if($item.Name.StartsWith('main::')){$functions[$item.Name.Substring(6)]}else{(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $root $item.Name)).Hash}
 if($actual -ne $item.Value){throw ('Protected gameplay code changed: '+$item.Name)}
 $checked++
}
Write-Output ('SCOPE PASS: '+$checked+' checks / rules, input, timing, ball physics and attack decisions unchanged')
@{checked=$checked;unchanged=$true;modified_main_functions=@('move_players','tactical_target');protected_files=@('src/timing.gd','src/ball_flight.gd','src/tactics.gd','controls.cfg')} | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $root 'docs\motion-scope-validation.json')
