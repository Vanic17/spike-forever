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

func original_region(file: String, region: Rect2i) -> Texture2D:
	var image := Image.load_from_file("res://assets/art/sponsors/"+file)
	if image == null: return null
	image=image.get_region(region)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

func _ready() -> void:
	for source in SOURCES: logos.append(original_region(source.file,source.region))
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
	apply_cycle()

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
		material.set_shader_parameter("ratio_a",float(SOURCES[a].region.size.x)/SOURCES[a].region.size.y)
		material.set_shader_parameter("ratio_b",float(SOURCES[b].region.size.x)/SOURCES[b].region.size.y)
		material.set_shader_parameter("background_a",SOURCES[a].background)
		material.set_shader_parameter("background_b",SOURCES[b].background)

func _process(dt: float) -> void:
	elapsed+=dt
	if elapsed>=PERIOD:
		elapsed=fmod(elapsed,PERIOD); cycle+=1; apply_cycle()
	var transition:=clampf((elapsed-(PERIOD-0.55))/0.55,0.0,1.0)
	for material in panels: material.set_shader_parameter("transition",transition)
