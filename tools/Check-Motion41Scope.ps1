$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot
$taskBaseline=Get-Content -Raw -LiteralPath (Join-Path $taskRoot 'docs/animation41-original-hashes.json') | ConvertFrom-Json
$taskChecked=0
foreach($taskEntry in $taskBaseline.PSObject.Properties){
 $taskPath=Join-Path $taskRoot $taskEntry.Name
 if(!(Test-Path -LiteralPath $taskPath)){throw ('Original file missing: '+$taskEntry.Name)}
 if((Get-FileHash -LiteralPath $taskPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $taskEntry.Value){throw ('Original scope changed: '+$taskEntry.Name)}
 $taskChecked++
}
Write-Output ('MOTION41 SCOPE PASS: '+$taskChecked+' original files unchanged / PSA and PSK / original native library / controls / ball physics / tactics / rules / timing / PlayStyles')
