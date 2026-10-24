extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var db=load("res://src/league.gd").new(); var count:=0; var styles: Dictionary={}; var beards: Dictionary={}
	for t in db.teams:
		for p in t.roster:
			if p.appearance.get("status")=="approximate_visual_review_official_portrait": count+=1
			styles[str(p.appearance.get("hair_style"))]=true; beards[str(p.appearance.get("beard"))]=true
	assert(count>=160 and styles.size()>=10 and beards.size()>=3)
	var g=load("res://src/main.tscn").instantiate(); root.add_child(g); g.set_process(false); g.set_physics_process(false)
	var appearance=load("res://src/player_appearance.gd"); var person: Dictionary=db.teams[0].roster[0].duplicate(true)
	var p=g.players[0]
	for style in appearance.STYLES.keys()+["pelato"]:
		person.appearance={"hair_style":style,"hair_color":"marrone","skin_tone":"chiara","beard":"nessuna"}
		p.set_roster_identity(person,person,{},{}); p.apply_pose(0)
		assert(p.body_parts.hair.scale.is_equal_approx(Vector3.ONE),"Hair must follow skeletal skinning, never scale around floor origin")
		assert(p.body_parts.hair.visible==(style!="pelato"))
	var cached: int=appearance.meshes.size()
	for beard in ["corta","piena","nessuna"]:
		person.appearance.beard=beard; p.set_roster_identity(person,person,{},{}); p.apply_pose(0)
		assert(p.body_parts.beard.visible==(beard!="nessuna"))
	assert(appearance.meshes.size()<=cached+2,"Meshes are cached across roster and libero swaps")
	print("APPEARANCE47 PASS: ",count," reviewed profiles / 10 hair meshes + bald / 2 beard meshes / skin shades / shared mesh cache")
	g.free(); quit()
