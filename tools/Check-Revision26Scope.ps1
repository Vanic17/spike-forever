$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$baseline=Join-Path $root 'docs/baseline-v25'
$script:checks=0
$functionPattern='(?ms)^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\z)'

function Read-Source([string]$name,[bool]$old=$false){
 $path=if($old){Join-Path $baseline $name}elseif($name -eq 'controls.cfg'){Join-Path $root $name}else{Join-Path $root ('src/'+$name)}
 return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8).Replace("`r`n","`n")
}
function Assert-Same([string]$old,[string]$new,[string]$label){
 if($old.Trim() -ne $new.Trim()){throw ('Unexpected revision26 change: '+$label)}
 $script:checks++
}
function Strip-VisualSelections([string]$source){
 # These single-line calls select a pose; they do not drive the simulation.
 return [regex]::Replace($source,'(?m)^.*\.select_variant\([^\r\n]*\)[ \t]*\n?','')
}
function Assert-Functions([string]$name,[string[]]$allowed=@(),[string[]]$visualSelections=@(),[string]$headerIgnore=''){
 $old=Read-Source $name $true
 $new=Read-Source $name
 $oldMethods=@{}
 foreach($method in [regex]::Matches($old,$functionPattern)){
  $methodName=$method.Groups[1].Value
  $oldMethods[$methodName]=$true
  if($methodName -in $allowed){continue}
  $current=[regex]::Match($new,('(?ms)^(?:static )?func '+[regex]::Escape($methodName)+'\(.*?(?=^(?:static )?func |\z)')).Value
  $previous=$method.Value
  if($name -eq 'main.gd' -and $methodName -eq 'plan_attack'){
   # A late normal/quick choice shares the already chosen visual pair. Only
   # that visual cache key loses the tempo flag; attack planning stays exact.
   $oldVisualKey='var visual_key:=str([shot_serial,setter,planned_hitter,planned_direction,planned_fast])'
   $stableVisualKey='var visual_key:=str([shot_serial,setter,planned_hitter,planned_direction])'
   Assert-Same $stableVisualKey ([regex]::Match($current,'(?m)^\tvar visual_key:=[^\r\n]*').Value.Trim()) 'main.gd: stable visual pair key'
   $current=$current.Replace($stableVisualKey,$oldVisualKey)
  }
  if($name -eq 'main.gd' -and $methodName -eq 'reset_rally'){
   # Reset the visual action before aliases are restored, so select_variant
   # cannot reject the reset while the previous rally's clip is recovering.
   # Validate only this exact move of the already existing idle call.
   $idleLine="`t`tp.play(""idle"", 1, true)`n"
   $yawLine="`t`tp.setting_yaw = PI if i<6 else 0.0`n"
   $liberoLine="`t`tp.set_libero(Tactics.libero(i, rotations[int(i / 6)], int(i / 6) == server))`n"
   if(([regex]::Matches($previous,[regex]::Escape($idleLine))).Count -ne 1 -or !$previous.Contains($liberoLine+$idleLine)){throw 'Unexpected baseline visual reset order'}
   $previous=$previous.Replace($liberoLine+$idleLine,$liberoLine).Replace($yawLine,$yawLine+$idleLine)
  }
  if($methodName -in $visualSelections){$current=Strip-VisualSelections $current; $previous=Strip-VisualSelections $previous}
  Assert-Same $previous $current ($name+':'+$methodName)
 }
 foreach($method in [regex]::Matches($new,$functionPattern)){
  $methodName=$method.Groups[1].Value
  if(!$oldMethods.ContainsKey($methodName) -and $methodName -notin $allowed){throw ('Unreviewed revision26 helper: '+$name+':'+$methodName)}
 }
 $oldHeader=[regex]::Replace($old,$functionPattern,'')
 $newHeader=[regex]::Replace($new,$functionPattern,'')
 if($headerIgnore){$oldHeader=[regex]::Replace($oldHeader,$headerIgnore,'');$newHeader=[regex]::Replace($newHeader,$headerIgnore,'')}
 Assert-Same $oldHeader $newHeader ($name+':module declarations')
}

# Regulatory identity, sideout logic, input/camera, power/timing and trajectory
# integration are the validated 0.25.0 implementation, byte for byte.
foreach($name in @('rotation_model.gd','rotation_context.gd','rally_lanes.gd','tactics.gd','rally_ai.gd','court_shape.gd','defensive_lanes.gd','setter_access.gd','reference_style.gd','controls.cfg','timing.gd','view_controls.gd','manual_wall.gd','ball_flight.gd','ball_contact.gd','approach_planner.gd','movement_intent.gd','pose_animation_tree.gd','source_assets.gd','arena.gd','match_audio.gd')){
 Assert-Same (Read-Source $name $true) (Read-Source $name) $name
}

# Fix only the two off-centre libero reception coordinates (R2 and R5).
$oldLayout=Read-Source 'serve_layout.gd' $true
if(([regex]::Matches($oldLayout,[regex]::Escape('[-2.6,6.8]'))).Count -ne 2){throw 'Unexpected 0.25.0 reception baseline'}
$expectedLayout=$oldLayout.Replace('[-2.6,6.8]','[0.0,6.3]')
Assert-Same $expectedLayout (Read-Source 'serve_layout.gd') 'serve_layout.gd: two R2/R5 libero coordinates only'

Assert-Functions 'main.gd' @() @('plan_attack','queue_recovery','request_block_jump')
Assert-Functions 'psa_animation_library.gd' @() @() '(?m)^const CLIPS :=.*\n?'
$oldClipLine=[regex]::Match((Read-Source 'psa_animation_library.gd' $true),'(?m)^const CLIPS :=.*').Value
$newClipLine=[regex]::Match((Read-Source 'psa_animation_library.gd'),'(?m)^const CLIPS :=.*').Value
$oldClipNames=@([regex]::Matches($oldClipLine,'"([^"]+)"') | ForEach-Object {$_.Groups[1].Value})
$newClipNames=@([regex]::Matches($newClipLine,'"([^"]+)"') | ForEach-Object {$_.Groups[1].Value})
foreach($name in $oldClipNames){
 if($name -notin $newClipNames){throw ('Existing native animation removed: '+$name)}
 $script:checks++
}
if(@($newClipNames | Select-Object -Unique).Count -ne $newClipNames.Count){throw 'Duplicate native animation names'}
Assert-Functions 'psa.gd' @('detect_contact')
$oldParser=Read-Source 'psa.gd' $true
$newParser=Read-Source 'psa.gd'
$eventPattern='(?ms)^func detect_contact\(.*?(?=^func |\z)'
$oldEvent=[regex]::Match($oldParser,$eventPattern).Value
$newEvent=[regex]::Match($newParser,$eventPattern).Value
# New clip names may map to the existing families. Contact inference, jump
# boost, ground reference, recovery events and all sampled math remain exact.
$familyPattern='(?m)^\tfor family in \[[^\r\n]*\]:\n?'
$familyMapLine="`taction = preload(""res://src/animation_expansion.gd"").FAMILIES.get(action,action)`n"
$newEvent=$newEvent.Replace($familyMapLine,'')
Assert-Same ([regex]::Replace($oldEvent,$familyPattern,'')) ([regex]::Replace($newEvent,$familyPattern,'')) 'psa.gd: contact inference below family names'

Assert-Functions 'avatar.gd' @('setup','ensure_native_tree','choose_gait') @() '(?m)^const AnimationExpansion\s*=.*\n?'
$oldAvatar=Read-Source 'avatar.gd' $true
$newAvatar=Read-Source 'avatar.gd'
$setupPattern='(?ms)^func setup\(.*?(?=^func |\z)'
$setupExtension=@(
 "`tfor action in [""idle"",""ready"",""relaxed"",""block_ready"",""run"",""walk"",""backwalk"",""backpedal"",""shuffle_left"",""shuffle_right"",""cross_left"",""cross_right""]:",
 "`t`tvar variant := AnimationExpansion.stance_or_gait(action,side,jersey)",
 "`t`tif source_clips.has(variant):",
 "`t`t`tclips[action]=source_clips[variant]",
 "`t`t`tvariant_names[action]=variant"
) -join "`n"
$newSetup=[regex]::Match($newAvatar,$setupPattern).Value.Replace($setupExtension+"`n",'')
Assert-Same ([regex]::Match($oldAvatar,$setupPattern).Value) $newSetup 'avatar.gd: setup only assigns visual aliases'
$treePattern='(?ms)^func ensure_native_tree\(.*?(?=^func |\z)'
$oldTree=[regex]::Match($oldAvatar,$treePattern).Value
$newTree=[regex]::Match($newAvatar,$treePattern).Value.Replace('pose_tree.setup(source_clips, func(name: String,time: float,loop: bool): return psa_normalized_pose("source:"+name,time,loop))','pose_tree.setup(source_clips, Callable(self, "psa_normalized_pose"))')
Assert-Same $oldTree $newTree 'avatar.gd: native library sampler only bypasses visual aliases'
$gaitPattern='(?ms)^func choose_gait\(.*?(?=^func |\z)'
$oldGait=[regex]::Match($oldAvatar,$gaitPattern).Value
$wallStepsLine="`tif block_ready_stance and action in [""shuffle_left"",""shuffle_right""] and clips.has(""wall_""+action): return ""wall_""+action`n"
$newGait=[regex]::Match($newAvatar,$gaitPattern).Value.Replace($wallStepsLine,'')
Assert-Same $oldGait $newGait 'avatar.gd: gait selector only adds wall shuffle performances'

# An additive registry must retain every old source identity and performance.
$oldSources=Get-Content -Raw -LiteralPath (Join-Path $baseline 'sources.json') | ConvertFrom-Json
$newSources=Get-Content -Raw -LiteralPath (Join-Path $root 'assets/active/sources.json') | ConvertFrom-Json
$oldHashes=Get-Content -Raw -LiteralPath (Join-Path $baseline 'original-animation-hashes.json') | ConvertFrom-Json
$newHashes=Get-Content -Raw -LiteralPath (Join-Path $root 'docs/original-animation-hashes.json') | ConvertFrom-Json
foreach($entry in $oldSources.PSObject.Properties){
 if($newSources.($entry.Name) -ne $entry.Value){throw ('An existing PSA source was replaced: '+$entry.Name)}
 if($newHashes.($entry.Name) -ne $oldHashes.($entry.Name)){throw ('An existing source hash was replaced: '+$entry.Name)}
 $active=Join-Path $root ('assets/active/'+$entry.Name+'.psa')
 if((Get-FileHash -LiteralPath $active -Algorithm SHA256).Hash -ne $oldHashes.($entry.Name)){throw ('An existing PSA performance was modified: '+$entry.Name)}
 $script:checks++
}
Write-Output ('REVISION26 SCOPE PASS: '+$script:checks+' checks / only two reception coordinates and visual animation selection expanded / rules, rotation slots, controls, timings, CPU choices, ball physics, pose solver and existing sources retained')
