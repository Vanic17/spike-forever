extends RefCounted
static func apply(arena,home: Color,visitor: Color):
	if not preload("res://src/visual_materials85.gd").enabled:return
	for material in arena.crowd_materials:
		material.set_shader_parameter("home_tint85",home)
		material.set_shader_parameter("visitor_tint85",visitor)
static func shader(shader: Shader) -> void:
	if not preload("res://src/visual_materials85.gd").enabled:return
	var code: String=shader.code
	code=code.replace("uniform float clothing=0.0;","uniform float clothing=0.0;\nuniform vec4 home_tint85 : source_color=vec4(0.08,0.2,0.4,1.0);\nuniform vec4 visitor_tint85 : source_color=vec4(0.5,0.15,0.12,1.0);\nuniform float visitor_sector85=0.0;")
	code=code.replace("varying vec4 person;","varying vec4 person;\nvarying float head_height85;")
	code=code.replace("person=INSTANCE_CUSTOM;","person=INSTANCE_CUSTOM;head_height85=VERTEX.y;")
	code=code.replace("vec3 shirt=COLOR.rgb*(0.45+lightness*0.65);","vec3 supporter=mix(home_tint85.rgb,visitor_tint85.rgb,step(0.89,person.w)*visitor_sector85);\n\tvec3 shirt=mix(COLOR.rgb,supporter,step(0.54,person.w)*0.85)*(0.65+lightness*0.45);")
	code=code.replace("ROUGHNESS=mix(0.66,0.90,clothing);","ROUGHNESS=mix(0.69,0.93,clothing);")
	code=code.replace("ALBEDO=mix(skin,shirt,clothing);","float hair_mask=smoothstep(1.12,1.23,head_height85)*(1.0-smoothstep(.08,.19,lightness));\n\tvec3 hair=mix(vec3(.025,.019,.015),vec3(.30,.22,.14),smoothstep(.2,.95,person.y));\n\tskin=mix(skin,hair*(.55+lightness*2.0),hair_mask*.65);\n\tALBEDO=mix(skin,shirt,clothing);")
	shader.code=code
