extends SceneTree
const PSA=preload("res://src/psa.gd")
const Converter=preload("res://src/psa_animation_library.gd")
const Expansion=preload("res://src/animation_expansion.gd")
var clips: Dictionary={}
var digests: Dictionary={}
var families: Dictionary={}

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var common_names: Array[String]=[]
	var common_parents: Array[int]=[]
	var compatible:=true
	var total_keys:=0
	for file in DirAccess.get_files_at("res://assets/active"):
		if not file.ends_with(".psa"): continue
		var action:=file.trim_suffix(".psa")
		var path:="res://assets/active/"+file
		var clip=PSA.new()
		assert(clip.load_file(path))
		clip.load_hierarchy("res://assets/active/skeleton.psk")
		clip.detect_contact(action)
		if common_names.is_empty():
			common_names=clip.names
			common_parents=clip.parents
		compatible=compatible and clip.names==common_names and clip.parents==common_parents
		var digest:=FileAccess.get_sha256(path)
		if not digests.has(digest): digests[digest]=[]
		digests[digest].append(action)
		var family: String=Expansion.FAMILIES.get(action,action)
		for prefix in ["attack","fast_set","receive","set","dive"]:
			if action.begins_with(prefix+"_"): family=prefix;break
		families[family]=int(families.get(family,0))+1
		total_keys+=clip.positions.size()
		clips[action]={"frames":clip.frames,"fps":clip.fps,"duration":clip.duration,"bones":clip.names.size(),"contact_time":clip.contact_time,"takeoff_time":clip.takeoff_time,"recovery_end":clip.recovery_end,"contact_offset":str(clip.contact_offset),"root_travel_m":str(clip.root_motion(clip.duration)),"native":action in Converter.CLIPS,"sha256":digest}
	var aliases: Array=[]
	for names in digests.values():
		if names.size()>1: aliases.append(names)
	var report: Dictionary={"active_files":clips.size(),"native_clips":Converter.CLIPS.size(),"psa_only_clips":clips.size()-Converter.CLIPS.size(),"unique_active_file_hashes":digests.size(),"identical_file_aliases":aliases,"bones":common_names.size(),"all_active_same_skeleton":compatible,"raw_bone_key_count":total_keys,"families":families,"names":common_names,"parents":common_parents,"clips":clips,"notes":["File-hash equality identifies exact copies only, not artistic similarity","Contact and recovery metadata are inferred by the existing parser, not authored source events","The source archive contains additional PSA files not automatically loaded or treated as playable clips"]}
	var output:=FileAccess.open("res://docs/animation41-source-audit.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	print("ANIMATION41 AUDIT PASS ",clips.size()," active files / ",digests.size()," exact unique files / ",Converter.CLIPS.size()," native clips / ",common_names.size()," bones / shared hierarchy ",compatible)
	quit(0 if compatible else 1)
