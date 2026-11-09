param([string]$OutputDirectory='dist',[switch]$SourceOnly)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
& (Join-Path $root 'tools/python311/python.exe') (Join-Path $root 'tools/Check-Audio85.py') --report .runtime/audio85-build-preflight.json
if($LASTEXITCODE -ne 0){throw 'Audio compatibility validation failed'}
$destination=[IO.Path]::GetFullPath((Join-Path $root $OutputDirectory))
New-Item -ItemType Directory -Force $destination | Out-Null
$files=@('project.godot','version.json','README.md','controls.cfg','Avvia Spike Forever.cmd','Spike Forever.exe','tools/Install-Update.ps1')
$files+=@('docs/RELEASE_NOTES_95_1.md','tools/Test-ShortSeconds101.gd','docs/short101-tests.json')
$files+=@('docs/RELEASE_NOTES_95.md','docs/MATCH_100.md','tools/Test-Match100.gd','tools/Test-MiddleRead100.gd','tools/Test-OnlineMatch100.gd','tools/Run-OnlineMatch100.ps1')
$files+=@('docs/RELEASE_NOTES_94.md','docs/CONDITION_99.md','tools/Test-Condition99.gd','tools/Test-ConditionIntegration99.gd','tools/Test-ConditionUI99.gd','tools/Test-OnlineCondition99.gd','tools/Run-OnlineCondition99.ps1','tools/Test-ConditionUpdate99.py','tools/Test-ConditionUpdate99.ps1','tools/Research-Forms99.py')
$files+=@('docs/RELEASE_NOTES_93.md','tools/Test-SetterSeconds98.gd','tools/Capture-SetterSeconds98.gd')
$files+=@('docs/RELEASE_NOTES_92.md','docs/perfect-set97-tests.json','tools/Test-PerfectSet97.gd','docs/RELEASE_NOTES_91.md','docs/STROKES_96.md','docs/NET_TIP94.md','docs/PLAYER_POSE95.md','tools/Test-Strokes96.gd','tools/Test-ShortTipRecovery96.gd','tools/Test-OnlineStrokes96.gd','tools/Run-OnlineStrokes96.ps1','tools/Capture-Strokes96.gd','tools/Test-NetTip94.gd','tools/Test-PlayerPose95.gd','tools/Verify-Package96.py')
foreach($pattern96 in @('match100-*','condition99-*','setter98-*','perfect-set97-*','strokes96-*','net-tip94-validation*','player-pose95-*')){
 foreach($item96 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern96){
  if($item96.Extension -in @('.json','.png','.mp4')){$files+='docs/'+$item96.Name}
 }
}
$files+='docs/RELEASE_NOTES_69.md'
$files+='docs/RELEASE_NOTES_70.md'
$files+='docs/RELEASE_NOTES_71.md'
$files+='docs/RELEASE_NOTES_72.md'
$files+='docs/RELEASE_NOTES_72_1.md'
$files+='docs/RELEASE_NOTES_73.md'
$files+='docs/RELEASE_NOTES_74.md'
$files+='docs/RELEASE_NOTES_75.md'
$files+='docs/RELEASE_NOTES_76.md'
$files+='docs/RELEASE_NOTES_77.md'
$files+='docs/RELEASE_NOTES_78.md'
$files+='docs/RELEASE_NOTES_79.md'
$files+='docs/RELEASE_NOTES_80.md'
$files+='docs/RELEASE_NOTES_81.md'
$files+='docs/RELEASE_NOTES_82.md'
$files+='docs/RELEASE_NOTES_83.md'
$files+='docs/RELEASE_NOTES_84.md'
$files+='docs/RELEASE_NOTES_85.md'
$files+='docs/GRAPHICS_UPGRADE_85.md'
$files+='docs/AUDIO_EDITOR_85.md'
$files+=@('docs/RELEASE_NOTES_90.md','docs/STATURE_90.md','docs/RELEASE_NOTES_89.md','docs/GRAPHICS_89.md','docs/ATHLETE_NEXT_88.md','docs/ATHLETE_PROTOTYPE_87.md','docs/GRAPHICS_UPGRADE_86.md','docs/GRAPHICS86_REQUIRED_ASSETS.md')
foreach($report90 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'stature90-*' -or $_.Name -eq 'player-heights90-sources.json'}){$files+='docs/'+$report90.Name}
$files+=@('tools/Athlete87MeshRefinement.gd','tools/Fetch-Athlete88Source.py')
foreach($pattern89 in @('graphics89-*','quality89-*','crowd89-*','online89-*','athlete88-*','athlete87-*','graphics86-*')){
 foreach($item89 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern89){
  if($item89.Extension -in @('.json','.png','.html')){$files+='docs/'+$item89.Name}
 }
}
foreach($number89 in 86..90){
 foreach($item89 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter ('*'+$number89+'.*')){$files+='tools/'+$item89.Name}
}
foreach($pattern85 in @('graphics85-*','audio85-*')){
 foreach($report85 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern85){
  if($report85.Name -match '^graphics85-(noss|nosoft)-'){continue}
  if($report85.Extension -in @('.json','.png','.html')){$files+='docs/'+$report85.Name}
 }
}
foreach($tool85 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*85.*'){$files+='tools/'+$tool85.Name}
foreach($report84 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'fluidity84-*'){
 if($report84.Extension -in @('.json','.png')){$files+='docs/'+$report84.Name}
}
foreach($tool84 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*84.*'){$files+='tools/'+$tool84.Name}
$files+='docs/setter83-tests.json'
$files+='tools/Validate-83.ps1'
foreach($pattern82 in @('arena82-*','online82-*')){
 foreach($report82 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern82){
  if($report82.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report82.Name}
 }
}
foreach($tool82 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*82.*'){$files+='tools/'+$tool82.Name}
foreach($pattern81 in @('setter81-*','legend81-*')){
 foreach($report81 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern81){
  if($report81.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report81.Name}
 }
}
foreach($tool81 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*81.*'){$files+='tools/'+$tool81.Name}
foreach($pattern80 in @('defense80-*','attack80-*')){
 foreach($report80 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern80){
  if($report80.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report80.Name}
 }
}
foreach($tool80 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*80.*'){$files+='tools/'+$tool80.Name}
foreach($pattern79 in @('middle79-*','legend79-*','second79-*')){
 foreach($report79 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern79){
  if($report79.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report79.Name}
 }
}
foreach($tool79 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*79.*'){$files+='tools/'+$tool79.Name}
foreach($pattern78 in @('attack78-*','recovery78-*')){
 foreach($report78 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern78){
  if($report78.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report78.Name}
 }
}
foreach($tool78 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*78.*'){$files+='tools/'+$tool78.Name}
foreach($report77 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'defense77-*'){
 if($report77.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report77.Name}
}
foreach($tool77 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*77.*'){$files+='tools/'+$tool77.Name}
$files+='tools/Download-SelectiveUpdate.ps1'
foreach($pattern76 in @('defense76-*','reception76-*','selective76-*')){
 foreach($report76 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern76){
  if($report76.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report76.Name}
 }
}
foreach($tool76 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*76.*'){$files+='tools/'+$tool76.Name}
foreach($pattern75 in @('defense75-*','arcade75-*','update75-*')){
 foreach($report75 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern75){
  if($report75.Extension -in @('.md','.json','.png','.mp4')){$files+='docs/'+$report75.Name}
 }
}
foreach($report75 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'legend75-*'){
 if($report75.Extension -in @('.md','.json','.png')){$files+='docs/'+$report75.Name}
}
foreach($tool75 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*75.*'){$files+='tools/'+$tool75.Name}
foreach($report74 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'double74-*'){
 if($report74.Extension -in @('.md','.json','.png')){$files+='docs/'+$report74.Name}
}
foreach($tool74 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*74.*'){$files+='tools/'+$tool74.Name}
foreach($report73 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'legend73-*'){
 if($report73.Extension -in @('.md','.json','.png')){$files+='docs/'+$report73.Name}
}
foreach($tool73 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*73.*'){$files+='tools/'+$tool73.Name}
foreach($report72 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'legend72-*'){
 if($report72.Extension -in @('.md','.json','.png')){$files+='docs/'+$report72.Name}
}
foreach($tool72 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*72.*'){$files+='tools/'+$tool72.Name}
foreach($report71 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'bench71-*'){$files+='docs/'+$report71.Name}
foreach($tool71 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*71.*'){$files+='tools/'+$tool71.Name}
foreach($report70 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'arena70-*'){$files+='docs/'+$report70.Name}
foreach($tool70 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*70.*'){$files+='tools/'+$tool70.Name}
foreach($pattern69 in @('sideline69-*','substitution69-*')){
 foreach($report69 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern69){$files+='docs/'+$report69.Name}
}
foreach($tool69 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*69.*'){$files+='tools/'+$tool69.Name}
$files+='docs/RELEASE_NOTES_68.md'
foreach($report68 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'patch68-*'){$files+='docs/'+$report68.Name}
foreach($tool68 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*68.*'){$files+='tools/'+$tool68.Name}
$files+=@('docs/RELEASE_NOTES_67.md')
foreach($pattern67 in @('overall67-*','gameplay67-*','stats67-*','online67-*')){
 foreach($report67 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern67){$files+='docs/'+$report67.Name}
}
foreach($tool67 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*67.*'){$files+='tools/'+$tool67.Name}
$files+=@('docs/RELEASE_NOTES_66.md','docs/CAREER_AUDIT_66.md','docs/CAREER_DATA_66.md','docs/CAREER_BACKEND_66.md','docs/MATCH_MANAGEMENT_66.md','docs/REPLAY_BALANCE_66.md','docs/baseline-v65/block_response.gd','docs/baseline-v65/player_stats_v1.json')
foreach($pattern66 in @('career66-*','match66-*','replay66-*','online66-*','online-replay66-*')){
 foreach($report66 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern66){$files+='docs/'+$report66.Name}
}
foreach($tool66 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*66.*'){$files+='tools/'+$tool66.Name}
$files+=@('docs/REVISION_28.md','docs/RELEASE_NOTES_28.md')
$files+='docs/RELEASE_NOTES_29.md'
$files+='docs/RELEASE_NOTES_30.md'
$files+='docs/RELEASE_NOTES_31.md'
$files+='docs/RELEASE_NOTES_32.md'
$files+='docs/RELEASE_NOTES_33.md'
$files+='docs/RELEASE_NOTES_34.md'
$files+='docs/RELEASE_NOTES_35.md'
$files+='docs/RELEASE_NOTES_36.md'
$files+='docs/RELEASE_NOTES_37.md'
$files+='docs/RELEASE_NOTES_38.md'
$files+=@('docs/ARENA_38.md','docs/AUDIO_ARENA38.md')
$files+=@('docs/RELEASE_NOTES_39.md','docs/AUDIO_ARENA39.md','docs/AUDIO_BANK_39.md')
$files+='docs/RELEASE_NOTES_40.md'
$files+=@('docs/RELEASE_NOTES_41.md','docs/ANIMATION_AUDIT_41.md','docs/ANIMATION_PERFORMANCE_41.md')
$files+=@('docs/ANIMATION_GAMEPLAY_PARITY_41.md','docs/animation41-preview.mp4')
$files+=@('docs/attack41-integrated-preview.png','docs/dive41-integrated-preview.png')
$files+=@('docs/RELEASE_NOTES_42.md','docs/PERFORMANCE_42.md','docs/approach42-preview.mp4','docs/approach42-15.png','docs/approach42-40.png','docs/approach42-63.png')
$files+=@('docs/RELEASE_NOTES_43.md','docs/preparation43-before.json','docs/preparation43-after.json','tools/Test-RecoveryPresentation43.gd','tools/Benchmark-Preparation43.gd')
$files+=@('docs/RELEASE_NOTES_44.md','docs/attacks44-preview.mp4','docs/balance44-report.json','docs/first-tempo44-report.json')
$files+='docs/RELEASE_NOTES_45.md'
$files+='docs/RELEASE_NOTES_45_1.md'
$files+='docs/RELEASE_NOTES_46.md'
$files+='docs/RELEASE_NOTES_47.md'
$files+='docs/RELEASE_NOTES_48.md'
$files+=@('docs/RELEASE_NOTES_49.md','docs/match49-report.json','docs/match-menu49.png','tools/Test-MatchSetup49.gd','tools/Capture-MatchMenu49.gd')
$files+=@('docs/RELEASE_NOTES_50.md','docs/running50-preview.mp4','docs/running50-report-30.json','docs/running50-report-60.json','docs/running50-report-120.json','tools/Test-RunningAttack50.gd','tools/Preview-RunningAttack50.gd')
$files+=@('docs/crossing50-report.json','tools/Test-OutsideCrossing50.gd')
$files+=@('docs/RELEASE_NOTES_51.md','docs/preferences51-report.json','docs/handed51-report.json','docs/online51-host.json','docs/online51-guest.json','docs/discovery51-report.json','docs/menu51-home.png','docs/menu51-online.png','docs/menu51-preferences.png')
$files+='docs/handed51-preview.png'
$files+=@('docs/RELEASE_NOTES_52.md','docs/rally52-report.json','docs/block52-balance.json','docs/contact-traffic28-report.json','docs/baseline-v51/block_response.gd','docs/baseline-v51/shot_variation.gd','tools/Test-RallyFix52.gd','tools/Test-BlockBalance52.gd','tools/Test-ContactTraffic28.gd','tools/Test-RecoveryTraffic.gd')
$files+='docs/rally52-psa-report.json'
$files+='tools/Capture-Recovery52.gd'
$files+=@('docs/RELEASE_NOTES_53.md','docs/settings53-report.json','docs/settings53-controller.json','docs/settings53-video.json','tools/Test-Settings53.gd','tools/Test-ControllerSettings53.gd','tools/Test-Video53.gd','tools/Capture-Settings53.gd','tools/DisplayModes.exe')
$files+=@('docs/RELEASE_NOTES_54.md','docs/second-touch54-report.json','docs/corridors54-report.json','docs/coverage54-report.json','docs/dump54-report.json','docs/baseline-v53/court_shape.gd','docs/baseline-v53/cpu_defense.gd','docs/baseline-v53/block_coverage.gd','tools/Test-SecondTouch54.gd','tools/Test-SetCorridors54.gd','tools/Test-BlockCoverage54.gd','tools/Test-Dump54.gd','tools/Capture-Dump54.gd')
foreach($frame54 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Filter 'dump54-*.png' -File){$files+='docs/'+$frame54.Name}
$files+=@('docs/RELEASE_NOTES_55.md','docs/constructions55-report.json','docs/middle55-report.json','docs/details55-report.json','docs/baseline-v54/block_response.gd','docs/camera55-0.png','docs/camera55-3.png','tools/Test-Constructions55.gd','tools/Test-Middle55.gd','tools/Test-Details55.gd','tools/Capture-Camera55.gd')
$files+=@('docs/RELEASE_NOTES_56.md','docs/low-recovery56-report.json','docs/middle-space56-report.json','docs/recovery56-preview.mp4','tools/Test-LowRecovery56.gd','tools/Test-MiddleSpace56.gd','tools/Capture-Recovery56.gd')
$files+='tools/Test-ManualReception56.gd'
$files+=@('tools/Test-DiveClock56.gd','docs/dive-clock56-report.json')
$files+=@('docs/RELEASE_NOTES_57.md','docs/second-touch57-report.json','docs/receive-clock57-report.json','docs/yield-routes57-report.json','docs/rescue57-report.json','docs/scramble57-report.json','docs/long-pass57-report.json','docs/contact57-baseline.json','docs/contact57-after.json','docs/performance57-report.json','docs/rescue57-preview.mp4','docs/rescue57-capture-report.json')
$files+=@('tools/Test-SecondTouch57.gd','tools/Test-ReceiveClock57.gd','tools/Test-YieldRoutes57.gd','tools/Test-Rescue57.gd','tools/Test-Scramble57.gd','tools/Test-LongPass57.gd','tools/Diagnose-Contacts57.gd','tools/Benchmark-Contacts57.gd','tools/Capture-Rescue57.gd')
$files+=@('tools/Test-EmergencyAttack57.gd','docs/emergency-attack57-report.json')
$files+=@('tools/Test-MiddleReady57.gd','docs/middle-ready57-report.json','docs/middle-ready57-baseline.json')
$files+=@('docs/RELEASE_NOTES_58.md','docs/baseline-v57/block_response.gd','docs/block-balance58-report.json','tools/Test-BlockBalance58.gd')
$files+=@('docs/RELEASE_NOTES_59.md','docs/baseline-v58/main.gd','docs/baseline-v58/block_response.gd','tools/Diagnose-Blocks59.gd','tools/Test-BlockSeal59.gd','tools/Test-BlockFlight59.gd','tools/Test-BlockGeometry59.gd')
foreach($report59 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'block-*59*.json'){$files+='docs/'+$report59.Name}
$files+=@('docs/RELEASE_NOTES_60.md','tools/Test-Tutorial60.gd','tools/Test-TutorialUI60.gd','tools/Test-TutorialFlow60.gd','tools/Capture-Tutorial60.gd')
$files+=@('docs/RELEASE_NOTES_61.md','tools/Test-Arena61.gd','tools/Capture-Arena61.gd','docs/arena61-bench.png','docs/arena61-referee.png')
$files+=@('docs/RELEASE_NOTES_62.md','docs/ROTATIONS_62.md','docs/WHISTLE_62.md','tools/Test-Rotations62.gd','tools/Test-Transitions62.gd','tools/Test-MiddleReady62.gd','tools/Capture-Rotations62.gd','docs/rotations62-receive.png','docs/middle-ready62-report.json')
$files+=@('docs/RELEASE_NOTES_63.md','docs/PLAYER_STATS_63.md','docs/defense63-ratings.json','tools/Build-Defense63.py')
$files+=@('docs/RELEASE_NOTES_64.md','docs/FIRST_ATTACK_64.md','docs/baseline-v63/rotation_layout.gd','docs/baseline-v63/rally_ai.gd')
$files+=@('docs/RELEASE_NOTES_65.md','docs/BROADCAST_REPLAY_65.md','tools/Build-Branding65.py','tools/Fetch-Branding65.py','tools/Build-Whistles65.py')
foreach($pattern65 in @('branding65-*','broadcast65-*','replay65-*','online-replay65-*','online-contacts65-*','gameplay65-*')){
 foreach($report65 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern65){$files+='docs/'+$report65.Name}
}
foreach($tool65 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*65.gd'){$files+='tools/'+$tool65.Name}
foreach($pattern64 in @('first-attack64-*','middle64-*','second-touch64-*','online64-*')){
 foreach($report64 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter $pattern64){$files+='docs/'+$report64.Name}
}
foreach($tool64 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*64.gd'){$files+='tools/'+$tool64.Name}
foreach($report63 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'stats63-*'){$files+='docs/'+$report63.Name}
foreach($report63 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'online-*63-*.json'){$files+='docs/'+$report63.Name}
foreach($tool63 in Get-ChildItem -LiteralPath (Join-Path $root 'tools') -File -Filter '*63.gd'){$files+='tools/'+$tool63.Name}
$files+=@('tools/Test-RotationSpec.gd','tools/Test-ManualWall.gd','docs/rotations62-foot-replay.json')
$files+='tools/Test-RunningAttack62.gd'
foreach($report62 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'rotations62-*.json'){$files+='docs/'+$report62.Name}
$files+=@('docs/tutorial60-gameplay.json','docs/tutorial60-gameplay-60.json','docs/tutorial60-gameplay-psa.json','docs/tutorial60-ui.json','docs/tutorial60-flow.json')
foreach($capture60 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'tutorial60-*.png'){$files+='docs/'+$capture60.Name}
foreach($preview53 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'settings53-*.png'){ $files+='docs/'+$preview53.Name }
foreach($preview52 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'recovery52-preview-*.png'){ $files+='docs/'+$preview52.Name }
foreach($tool51 in @('Test-Preferences51.gd','Test-Handed51.gd','Test-Online51.gd','Test-HumanContacts51.gd','Test-OnlineUI51.gd','Test-LobbyLeave51.gd','Test-Discovery51.gd','Capture-Online51.gd')){ $files+='tools/'+$tool51 }
foreach($tool48 in @('Inspect-Middle48.gd','Test-FirstTempo48.gd','Preview-FirstTempo48.gd')){ $files+='tools/'+$tool48 }
foreach($report48 in @('first-tempo48-report.json','first-tempo48-preview.mp4','first-tempo48-set-0.png','first-tempo48-set-1.png','first-tempo48-set-2.png','first-tempo48-hit.png','first-tempo48-feint.png','approach48-contacts.json')){ $files+='docs/'+$report48 }
foreach($tool47 in @('Fetch-PlayerReferences47.py','Prepare-Appearance47.py','Build-PlayerProfiles47.py','Inspect-Contacts47.gd','Test-Tips47.gd','Test-Gameplay47.gd','Test-BlockRallies47.gd','Test-Appearance47.gd','Test-ProfileOverrides47.gd','Preview-Appearance47.gd','Benchmark-Rendered47.gd')){
 $files+='tools/'+$tool47
}
foreach($report47 in @('appearance47-sources.json','appearance47-presets.png','tips47-report.json','gameplay47-report.json','block-rallies47-report.json')){
 $files+='docs/'+$report47
}
foreach($tool46 in @('Inspect-Officials46.py','Prepare-Officials46.py','Build-Officials46.gd','Build-KitPreviews46.gd','Test-Equipment46.gd','Test-Preparation46.gd','Capture-Equipment46.gd','Capture-MatchMenu46.gd','Preview-Approaches46.gd')){
 $files+='tools/'+$tool46
}
foreach($report46 in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'equipment46-*.png' -or $_.Name -like 'approach46-*.png' -or $_.Name -in @('match-menu46.png','officials46-assets.json','preparation46-report.json','approach46-contact-report.json')}){
 $files+='docs/'+$report46.Name
}
foreach($kitTool in @('Build-Kits45.py','Inspect-KitMesh45.py','Fetch-KitReferences45.py','Fetch-ExtraKitReferences45.py','Test-Kits45.gd','Test-KitMatch45.gd','Preview-Kits45.gd','Benchmark-Kits45.gd','Capture-KitMatch45.gd','Check-KitScope45.py')){
 $files+='tools/'+$kitTool
}
foreach($kitReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'kits45-*.json' -or $_.Name -like 'kits45-*.png'}){
 $files+='docs/'+$kitReport.Name
}
foreach($taskTool in @('Preview-Attacks44.gd','Test-RallyBalance44.gd','Test-SweptBlock44.gd','Test-FirstTempo44.gd','Test-ForwardApproach44.gd')){
 $files+='tools/'+$taskTool
}
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File | Where-Object {$_.Name -like 'animation42-*.json' -or $_.Name -in @('approach42-report.json','scope42-report.json')}){
 $files+='docs/'+$taskReport.Name
}
foreach($taskTool in @('Preview-Approach42.gd','Benchmark-Rendered42.gd','Test-Approach42.gd','Test-SpecialistsPause42.gd')){
 $files+='tools/'+$taskTool
}
foreach($taskReport in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Filter 'animation41-*.json'){
 $files+='docs/'+$taskReport.Name
}
foreach($taskTool in @('Build-Motion41.gd','Test-Motion41.gd','Test-MotionGameplay41.gd','Check-Motion41Scope.ps1','Audit-Animation41.gd','Audit-Dive41.gd','Audit-Attack41.gd','Capture-Animation41.gd','Preview-Motion41.gd','Benchmark-Animation41.gd','Benchmark-AnimationPrototypes41.gd','Benchmark-RenderedMotion41.gd')){
 $files+='tools/'+$taskTool
}
foreach($name in @('ROLES_ROTATIONS_19.md','UPDATES_19.md','REVISION_18.md','ANIMATION_18.md','REVISION_20.md','REVISION_21.md','REVISION_22.md','REVISION_23.md','REVISION_24.md','REVISION_25.md','REVISION_26.md','REVISION_26_1.md','ANIMATION_24.md','ANIMATION_26.md','v26-rotation-audit.md','STRONG_SPIKES_V24.md','SPECIFICA_ROTazioni_5-1.md')){
 if(Test-Path (Join-Path $root ('docs/'+$name))){$files+='docs/'+$name}
}
foreach($folder in @('src','data','licenses','assets/ui','assets/active','assets/art','assets/arena_source','assets/mesh_source','assets/audio','assets/gameplay')){
 foreach($file in Get-ChildItem -LiteralPath (Join-Path $root $folder) -File -Recurse){
  if($file.Extension -in @('.import','.uid') -or $file.Name -eq 'native_stage1.res'){continue}
  # Rejected/offline art studies are deliberately outside the main game.
  $relative96=$file.FullName.Substring($root.Length+1).Replace('\','/')
  if($relative96 -match '^assets/art/(blender91|athlete92|player93)/' -or $relative96 -match '^src/(player_visual91|anatomical_player92|player_study93)\.gd$' -or $relative96 -match '^src/study93_' -or $file.Extension -in @('.blend','.blend1')){continue}
  $files+=$file.FullName.Substring($root.Length+1).Replace('\','/')
 }
}
if(!$SourceOnly){$files+='tools/godot/Godot_v4.5.1-stable_win64.exe'}
$files=@($files | Select-Object -Unique)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath=Join-Path $destination 'SpikeForever-Windows.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Output already exists; choose a new output directory'}
$manifest=[ordered]@{version=(Get-Content -Raw (Join-Path $root 'version.json') | ConvertFrom-Json).version;files=[ordered]@{}}
$zip=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
try{
 foreach($relative in $files){
  $file=Join-Path $root $relative
  $manifest.files[$relative]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
  [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file,$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
 }
 $entry=$zip.CreateEntry('release-manifest.json')
 $writer=[IO.StreamWriter]::new($entry.Open())
 try{$writer.Write(($manifest | ConvertTo-Json -Depth 8))}finally{$writer.Dispose()}
}finally{$zip.Dispose()}
& (Join-Path $root 'tools/python311/python.exe') (Join-Path $root 'tools/Build-UpdateIndex76.py') $zipPath (Join-Path $destination 'SpikeForever-UpdateIndex.json')
if($LASTEXITCODE -ne 0){throw 'Selective update index generation failed'}
Get-FileHash -LiteralPath $zipPath -Algorithm SHA256 | Format-List
