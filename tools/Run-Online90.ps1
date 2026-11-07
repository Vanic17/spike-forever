param([ValidateSet('database','substitutions','replay','contacts','jitter')][string]$Case='database')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
Set-Location $root
$definitions86=@{
 database=@{Script='Test-OnlineHeights90.gd';Marker='ONLINE82 DATABASE PASS'}
 substitutions=@{Script='Test-OnlineSubstitution69.gd';Marker='ONLINE SUBSTITUTION69 PASS'}
 replay=@{Script='Test-OnlineReplay65.gd';Marker='ONLINE REPLAY66 PASS'}
 contacts=@{Script='Test-Contacts90.gd';Marker='ONLINE CONTACTS65 PASS'}
 jitter=@{Script='Test-OnlineJitter89.gd';Marker='ONLINE CONTACTS65 PASS'}
}
$selected86=$definitions86[$Case]
$processes86=@()
foreach($role86 in @('host','guest')){
 $env:APPDATA=Join-Path $root ('.runtime/online82-graphics90-'+$Case+'-'+$role86+'-appdata')
 $env:LOCALAPPDATA=Join-Path $root ('.runtime/online82-graphics90-'+$Case+'-'+$role86+'-local')
 $arguments86=@('--headless','--path','.','--script',('tools/'+$selected86.Script))
 if($role86 -eq 'guest'){$arguments86+=@('--','--guest')}
 $p=Start-Process tools/godot/Godot_v4.5.1-stable_win64_console.exe -ArgumentList $arguments86 -WindowStyle Hidden -PassThru -RedirectStandardOutput ('.runtime/stature90-online-'+$Case+'-'+$role86+'.stdout.log') -RedirectStandardError ('.runtime/stature90-online-'+$Case+'-'+$role86+'.stderr.log')
 $handle86=$p.Handle;$processes86+=$p
 if($role86 -eq 'host'){Start-Sleep -Seconds 3}
}
foreach($p in $processes86){if(!$p.WaitForExit(60000)){Stop-Process -Id $p.Id;throw ('Timeout '+$Case)}}
foreach($role86 in @('host','guest')){
 $stdout86=Get-Content -Raw ('.runtime/stature90-online-'+$Case+'-'+$role86+'.stdout.log')
 $stderr86=Get-Content -Raw ('.runtime/stature90-online-'+$Case+'-'+$role86+'.stderr.log')
 if(!$stdout86.Contains($selected86.Marker) -or $stderr86 -match 'SCRIPT ERROR|SHADER ERROR|Parse Error|Assertion failed|Parameter "material" is null'){throw ('Online failed '+$Case+' '+$role86)}
}
[IO.File]::WriteAllText((Join-Path $root ('docs/stature90-online-'+$Case+'.json')),(@{pass=$true;clients=2;case=$Case;profile='isolated';transport='loopback ENet'} | ConvertTo-Json))
Write-Output ('ONLINE86 PASS '+$Case+' host / guest')
