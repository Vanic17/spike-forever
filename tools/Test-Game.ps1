$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$env:APPDATA=Join-Path $root '.runtime\roaming'
$env:LOCALAPPDATA=Join-Path $root '.runtime\local'
$engine=Join-Path $root 'tools\godot\Godot_v4.5.1-stable_win64_console.exe'
foreach($mode in @('self-test','fallback-test')){
 $log=Join-Path $root ('docs\'+$mode+'.log')
 $runtime=Join-Path $root ('docs\'+$mode+'-runtime.log')
 $ErrorActionPreference='Continue'
 & $engine --headless --path $root --log-file $runtime --quit-after 300 -- ('--'+$mode) *> $log
 $code=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 $issues=Select-String -Path $log -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed|Failed to load script|Invalid call|Shader compilation failed'
 if($code -ne 0 -or $issues){Write-Output ('FAIL '+$mode);Get-Content $log -Tail 30;exit 1}
 $reportName=if($mode -eq 'self-test'){'revision-contact-report.json'}else{'fallback-contact-report.json'}
 $report=Get-Content -Raw (Join-Path $root ('docs\'+$reportName)) | ConvertFrom-Json
 $minimumTravel=($report.travel_metres | Measure-Object -Minimum).Minimum
 if($report.points -lt 16 -or $report.contacts -le 35 -or $report.maximum_hand_ball_gap_m -gt 0.18 -or $minimumTravel -le 1){throw ('Scenario acceptance failed: '+$mode)}
 if($report.minimum_player_spacing_m -lt 0.775 -or $report.minimum_block_spacing_m -lt 0.775){throw ('Athletes overlapped: '+$mode)}
 if($report.duplicate_block_jumps -ne 0){throw ('Block jumped twice: '+$mode)}
 $duplicateJumps=$report.block_jump_events | Group-Object attack_id,player | Where-Object {$_.Count -gt 1}
 if($duplicateJumps){throw ('Repeated block event: '+$mode)}
 if($mode -eq 'self-test' -and !(Select-String -Path $log -Pattern 'PLAY LIFECYCLE PASS: 48')){throw 'Planned play and jump lifecycle regressions did not pass'}
 if($mode -eq 'self-test'){
  foreach($marker in @('CONTROL SYSTEM PASS','MANUAL INPUT PASS','REFERENCE CASES PASS')){
   if(!(Select-String -Path $log -Pattern $marker)){throw ('New contextual controls were not verified: '+$marker)}
  }
 }
 if(!(Select-String -Path $log -Pattern 'SIMULATION points=16')){throw ('Simulation did not complete: '+$mode)}
 Write-Output ('PASS '+$mode+' / punti '+$report.points+' / contatti '+$report.contacts+' / gap massimo '+[Math]::Round($report.maximum_hand_ball_gap_m,4)+'m / tutti i 12 atleti in movimento')
 Write-Output ('SPACING '+$mode+' / atleti '+[Math]::Round($report.minimum_player_spacing_m,3)+'m / muro '+[Math]::Round($report.minimum_block_spacing_m,3)+'m')
}
$motionLog=Join-Path $root 'docs\movement-quality-test.log'
$ErrorActionPreference='Continue'
& $engine --headless --path $root --script (Join-Path $root 'tools\Test-Movement.gd') *> $motionLog
$motionCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($motionCode -ne 0 -or (Select-String -Path $motionLog -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed') -or !(Select-String -Path $motionLog -Pattern 'MOVEMENT PASS')){
 Get-Content $motionLog -Tail 25
 throw 'Movement quality regression failed'
}
Write-Output 'PASS movement-quality / independent reactions / moving transitions / contact event retained'
$tacticalLog=Join-Path $root 'docs\tactical-motion-test.log'
$ErrorActionPreference='Continue'
& $engine --headless --path $root --script (Join-Path $root 'tools\Test-TacticalMotion.gd') --quit-after 180 *> $tacticalLog
$tacticalCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($tacticalCode -ne 0 -or (Select-String -Path $tacticalLog -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed') -or !(Select-String -Path $tacticalLog -Pattern 'TACTICAL MOTION PASS')){
 Get-Content $tacticalLog -Tail 25
 throw 'Tactical movement continuity regression failed'
}
Write-Output 'PASS tactical-motion / 432 role targets / proactive reads / coverage lanes / continuous support velocity / 60-120Hz'
$avatarLog=Join-Path $root 'docs\avatar-motion-test.log'
$ErrorActionPreference='Continue'
& $engine --headless --path $root --script (Join-Path $root 'tools\Test-AvatarMotion.gd') --quit-after 180 *> $avatarLog
$avatarCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($avatarCode -ne 0 -or (Select-String -Path $avatarLog -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed') -or !(Select-String -Path $avatarLog -Pattern 'AVATAR MOTION PASS')){
 Get-Content $avatarLog -Tail 25
 throw 'Avatar anatomy and animation continuity regression failed'
}
Write-Output 'PASS avatar-motion / continuous joints / limb lengths / actual dive and get-up / source serve travel / lateral footwork'
$referenceLog=Join-Path $root 'docs\reference-profile-test.log'
$ErrorActionPreference='Continue'
& $engine --headless --path $root --script (Join-Path $root 'tools\Test-Reference.gd') *> $referenceLog
$referenceCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($referenceCode -ne 0 -or (Select-String -Path $referenceLog -Pattern 'SCRIPT ERROR|Assertion failed') -or !(Select-String -Path $referenceLog -Pattern 'REFERENCE PASS')){throw 'Extracted formations and restored ball physics regression failed'}
Write-Output 'PASS reference / 144 mirrored positions / 12 formations / roles / revision 08 ball physics / arrival curve'
foreach($check in @(@('Positioning','POSITIONING PASS'),@('MotionContinuity','MOTION CONTINUITY PASS'),@('BallContinuity','BALL CONTINUITY PASS'),@('CourtFlow','COURT FLOW PASS'),@('ServeAndVariety','SERVE VARIETY PASS'),@('ManualWall','MANUAL WALL PASS'),@('MiddleDecoy','MIDDLE DECOY PASS'),@('TrafficRead','TRAFFIC READ PASS'),@('Fluidity','FLUIDITY PASS'),@('SetterRotation','SETTER ROTATION PASS'),@('NativeAnimation','NATIVE ANIMATION PASS'),@('ReceptionLanes','RECEPTION LANES PASS'),@('RecoveryTraffic','RECOVERY TRAFFIC PASS'))){
 $name=$check[0]; $marker=$check[1]
 $extraLog=Join-Path $root ('docs\'+$name+'-test.log')
 $ErrorActionPreference='Continue'
 & $engine --headless --path $root --script (Join-Path $root ('tools\Test-'+$name+'.gd')) --quit-after 180 *> $extraLog
 $extraCode=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 if($extraCode -ne 0 -or (Select-String -Path $extraLog -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed') -or !(Select-String -Path $extraLog -SimpleMatch $marker)){
  Get-Content $extraLog -Tail 25
  throw ('Movement and positioning regression failed: '+$name)
 }
 Write-Output ('PASS '+$name+' / '+$marker)
}
foreach($check in @(@('RoleMatrix','ROLE MATRIX PASS'),@('MenuUpdates','MENU UPDATES PASS'))){
 $extraLog=Join-Path $root ('docs\'+$check[0]+'-test.log')
 $ErrorActionPreference='Continue'
 & $engine --headless --path $root --script (Join-Path $root ('tools\Test-'+$check[0]+'.gd')) --quit-after 180 *> $extraLog
 $extraCode=$LASTEXITCODE
 $ErrorActionPreference='Stop'
 if($extraCode -ne 0 -or (Select-String -Path $extraLog -Pattern 'SCRIPT ERROR|Parse Error|Assertion failed') -or !(Select-String -Path $extraLog -SimpleMatch $check[1])){
  Get-Content $extraLog -Tail 25
  throw ('Role or update regression failed: '+$check[0])
 }
 Write-Output ('PASS '+$check[0]+' / '+$check[1])
}
& (Join-Path $PSScriptRoot 'Check-PositionScope.ps1')
& (Join-Path $PSScriptRoot 'Check-Revision19Scope.ps1')
& (Join-Path $PSScriptRoot 'Test-UpdateInstaller.ps1')
exit 0
