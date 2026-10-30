extends Node3D
## All marks are original images published on Lega Volley's sponsor page.
## Regions only remove document margins; no logo is redrawn or stretched.
const SOURCES := [
	{"name":"Credem Banca", "file":"credem-original.png", "region":Rect2i(43,726,1234,755), "background":Color.WHITE},
	{"name":"Del Monte", "file":"delmonte-original.jpg", "region":Rect2i(60,0,1108,850), "background":Color.WHITE},
	{"name":"Mikasa", "file":"mikasa-original.jpg", "region":Rect2i(0,0,1664,533), "background":Color("fff000")},
	{"name":"+Adrenalina", "file":"adrenalina-original.png", "region":Rect2i(14,20,382,86), "background":Color.WHITE}
]
const PERIOD := 8.0
var elapsed := 0.0
var cycle := 0
var panels: Array[ShaderMaterial] = []
var logos: Array[Texture2D] = []
var court_marks: Array[MeshInstance3D] = []
var led_shader: Shader
var source_rows: Array = []
var club_marks: Array[MeshInstance3D] = []
var club_id := ""
var artwork_cache: Dictionary = {}

func original_region(file: String, region: Rect2i) -> Texture2D:
	var image := Image.load_from_file("res://assets/art/sponsors/"+file)
	if image == null: return null
	image=image.get_region(region)
	return preload("res://src/texture_quality.gd").create(image,"res://assets/art/sponsors/"+file,region)

func _ready() -> void:
	for source in SOURCES:
		logos.append(original_region(source.file,source.region))
		source_rows.append({"ratio":float(source.region.size.x)/source.region.size.y,"background":source.background})
	led_shader=Shader.new()
	led_shader.code="""shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D logo_a : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D logo_b : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 background_a : source_color = vec4(1.0);
uniform vec4 background_b : source_color = vec4(1.0);
uniform float ratio_a=2.0;
uniform float ratio_b=2.0;
uniform float aspect=6.0;
uniform float transition=0.0;
vec3 panel(sampler2D mark,vec4 bg,float ratio,vec2 uv){
	float repeats=max(1.0,floor(aspect/(ratio*0.85+0.5)));
	float cell=aspect/repeats;
	vec2 logo_uv=vec2((fract(uv.x*repeats)-0.5)*cell/(ratio*0.83)+0.5,(uv.y-0.5)/0.83+0.5);
	if(any(lessThan(logo_uv,vec2(0.0))) || any(greaterThan(logo_uv,vec2(1.0)))) return bg.rgb;
	return texture(mark,logo_uv).rgb;
}
void fragment(){
	vec3 old=panel(logo_a,background_a,ratio_a,UV);
	vec3 next=panel(logo_b,background_b,ratio_b,UV);
	float wipe=smoothstep(UV.x-0.08,UV.x+0.08,transition*1.16-0.08);
	vec3 color=mix(old,next,wipe);
	float pixels=0.97+0.03*sin(UV.y*1450.0);
	ALBEDO=color*pixels;
	EMISSION=color*0.25;
}"""
	for side in [-1,1]:
		for segment in 4:
			add_panel(Vector3(side*9.3,0.58,(segment-1.5)*6.0),Vector2(5.92,0.92),-side*PI/2)
		for segment in 3:
			add_panel(Vector3((segment-1)*6.1,0.58,side*14.5),Vector2(6.02,0.92),PI if side>0 else 0.0)
	# Elevated fascia uses the same original artwork, behind spectators.
	for side in [-1,1]:
		for segment in 4:
			add_panel(Vector3(side*21.1,5.8,(segment-1.5)*7.3),Vector2(7.15,0.7),-side*PI/2)
	var parquet_logo:=original_region("credem-original.png",Rect2i(43,726,1234,641))
	var parquet_shader:=Shader.new()
	parquet_shader.code="""shader_type spatial;
uniform sampler2D logo : source_color, filter_linear_mipmap_anisotropic;
void fragment(){
	vec3 ink=texture(logo,UV).rgb;
	if(all(greaterThan(ink,vec3(0.97)))) discard;
	ALBEDO=ink; ROUGHNESS=0.48;
}"""
	for side in [-1,1]:
		var decal:=MeshInstance3D.new()
		decal.name="CredemCourt"+str(side)
		var plane:=PlaneMesh.new(); plane.size=Vector2(3.7,3.7*641.0/1234.0)
		decal.mesh=plane
		decal.position=Vector3(3.0,0.030,side*5.7)
		decal.rotation.y=PI/2
		var material:=ShaderMaterial.new()
		material.shader=parquet_shader
		material.set_shader_parameter("logo",parquet_logo)
		decal.material_override=material
		decal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(decal); court_marks.append(decal)
	# Del Monte is fixed on both near-side free zones in every home profile.
	for side in [-1,1]:
		var mark := floor_mark(logos[1],Vector3(5.5,0.033,side*1.65),Vector2(2.1,2.1*850.0/1108.0),PI/2)
		mark.name = "DelMonteCourt" + str(side)
	apply_cycle()

func floor_mark(texture: Texture2D, at: Vector3, size: Vector2, angle: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var plane := PlaneMesh.new(); plane.size = size; node.mesh = plane
	node.position = at; node.rotation.y = angle
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture; material.albedo_color = Color.WHITE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = .55; material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	node.material_override = material; node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func club_texture(key: String) -> Texture2D:
	if artwork_cache.has(key): return artwork_cache[key]
	var row: Dictionary = preload("res://src/arena_profiles.gd").artwork(key)
	if row.is_empty(): return null
	var path: String = "res://" + str(row.path)
	var image := Image.load_from_file(path)
	if image == null or image.is_empty(): return null
	artwork_cache[key] = preload("res://src/texture_quality.gd").create(image,path)
	return artwork_cache[key]

func set_club(club: String) -> void:
	if club_id == club: return
	var profile: Dictionary = preload("res://src/arena_profiles.gd").profile(club)
	if profile.is_empty(): return
	for mark in club_marks:
		remove_child(mark); mark.queue_free()
	club_marks.clear(); logos.clear(); source_rows.clear(); artwork_cache.clear()
	# League partners stay in rotation alongside the home club's sponsors.
	for key in profile.sponsors:
		var texture := club_texture(str(key))
		if texture == null: continue
		var artwork: Dictionary = preload("res://src/arena_profiles.gd").artwork(str(key))
		logos.append(texture); source_rows.append({"ratio":float(texture.get_width())/texture.get_height(),"background":Color(artwork.get("background","#ffffff"))})
	for source in SOURCES:
		logos.append(original_region(source.file,source.region))
		source_rows.append({"ratio":float(source.region.size.x)/source.region.size.y,"background":source.background})
	for placement in profile.floor:
		var texture := club_texture(str(placement.mark))
		if texture == null: continue
		var node := floor_mark(texture,Vector3(placement.x,.034,placement.z),Vector2(placement.width,placement.height),float(placement.get("yaw",90))*PI/180)
		node.name = "HomeSponsor_"+str(placement.mark)
		club_marks.append(node)
	club_id = club; cycle = 0; elapsed = 0; apply_cycle()
	for material in panels: material.set_shader_parameter("transition",0.0)

func add_panel(at: Vector3,size: Vector2,angle: float) -> void:
	var node:=MeshInstance3D.new()
	var quad:=QuadMesh.new(); quad.size=size; node.mesh=quad
	node.position=at; node.rotation.y=angle
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:=ShaderMaterial.new(); material.shader=led_shader
	material.set_shader_parameter("aspect",size.x/size.y)
	node.material_override=material; panels.append(material); add_child(node)

func apply_cycle() -> void:
	for i in panels.size():
		var a: int=(cycle+int(i/4))%logos.size()
		var b: int=(a+1)%logos.size()
		var material:=panels[i]
		material.set_shader_parameter("logo_a",logos[a])
		material.set_shader_parameter("logo_b",logos[b])
		material.set_shader_parameter("ratio_a",source_rows[a].ratio)
		material.set_shader_parameter("ratio_b",source_rows[b].ratio)
		material.set_shader_parameter("background_a",source_rows[a].background)
		material.set_shader_parameter("background_b",source_rows[b].background)

func _process(dt: float) -> void:
	elapsed+=dt
	if elapsed>=PERIOD:
		elapsed=fmod(elapsed,PERIOD); cycle+=1; apply_cycle()
	var transition:=clampf((elapsed-(PERIOD-0.55))/0.55,0.0,1.0)
	for material in panels: material.set_shader_parameter("transition",transition)
