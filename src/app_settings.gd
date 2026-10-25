extends Node
const Textures=preload("res://src/texture_quality.gd")
const Language=preload("res://src/localization.gd")
const DEFAULTS={"language":"it","mode":1,"width":1920,"height":1080,"native_resolution":true,"hz":0,"fps":0,"vsync":1,"textures":0,"scale":1.0,"scaling_mode":0,"aa":2,"taa":false,"shadows":2,"shadow_distance":55.0,"ssao":true,"ssil":false,"ssr":false,"exposure":1.0,"glow":true,"crowd":2,"anisotropy":3,"preset":-1}
const PRESETS=[
	{"textures":512,"scale":.67,"scaling_mode":1,"aa":0,"taa":false,"shadows":1,"shadow_distance":30.0,"ssao":false,"ssil":false,"ssr":false,"glow":false,"crowd":0,"anisotropy":1},
	{"textures":1024,"scale":.85,"scaling_mode":1,"aa":1,"taa":false,"shadows":1,"shadow_distance":55.0,"ssao":true,"ssil":false,"ssr":false,"glow":false,"crowd":1,"anisotropy":2},
	{"textures":2048,"scale":1.0,"scaling_mode":0,"aa":2,"taa":false,"shadows":2,"shadow_distance":55.0,"ssao":true,"ssil":false,"ssr":false,"glow":true,"crowd":2,"anisotropy":3},
	{"textures":0,"scale":1.0,"scaling_mode":0,"aa":3,"taa":false,"shadows":3,"shadow_distance":80.0,"ssao":true,"ssil":true,"ssr":true,"glow":true,"crowd":2,"anisotropy":4}
]
var data: Dictionary=DEFAULTS.duplicate()
var config_path:="user://settings.cfg"
var game
var dry_run:=false
var translation: Translation
var italian_translation: Translation
var displays: Array=[]
var original_mode: Dictionary={}
var active_device:=""
var display_changed:=false
var loaded:=false
var last_error:=""
func _ready():
	translation=Language.new(); translation.locale="en"; TranslationServer.add_translation(translation)
	italian_translation=Language.new(); italian_translation.locale="it"; TranslationServer.add_translation(italian_translation)
	dry_run=DisplayServer.get_name()=="headless" or "--settings-test" in OS.get_cmdline_user_args()
	load_config(); TranslationServer.set_locale(data.language); Textures.max_size=data.textures
	if not loaded:
		var window=get_window()
		data.mode=2 if window.mode==Window.MODE_EXCLUSIVE_FULLSCREEN else (1 if window.mode==Window.MODE_FULLSCREEN else 0)
		data.width=maxi(1024,window.size.x); data.height=maxi(600,window.size.y)
	if not dry_run: discover_displays()
	call_deferred("startup")
func load_config():
	var config=ConfigFile.new(); loaded=config.load(config_path)==OK
	var proposed=DEFAULTS.duplicate()
	if loaded:
		for key in DEFAULTS: proposed[key]=config.get_value("settings",key,DEFAULTS[key])
	data=sanitize(proposed)
func save_config() -> Error:
	var config=ConfigFile.new()
	for key in data: config.set_value("settings",key,data[key])
	var error:=config.save(config_path+".tmp")
	if error!=OK: return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(config_path+".tmp"),ProjectSettings.globalize_path(config_path))
static func sanitize(values: Dictionary) -> Dictionary:
	var result=DEFAULTS.duplicate()
	for key in DEFAULTS:
		if values.has(key) and typeof(values[key])==typeof(DEFAULTS[key]): result[key]=values[key]
	if result.language not in ["it","en"]: result.language="it"
	for key in ["mode","shadows","crowd"]: result[key]=clampi(result[key],0,2 if key!="shadows" else 3)
	result.width=clampi(result.width,1024,7680); result.height=clampi(result.height,600,4320)
	if result.hz<0 or result.hz>600: result.hz=0
	if result.fps not in [0,30,60,90,120,144,165,180,240,360]: result.fps=0
	if result.textures not in [0,512,1024,2048]: result.textures=0
	result.scale=clampf(result.scale,.5,1.0); result.aa=clampi(result.aa,0,3); result.anisotropy=clampi(result.anisotropy,0,4); result.vsync=clampi(result.vsync,0,3)
	result.scaling_mode=clampi(result.scaling_mode,0,1); result.shadow_distance=clampf(result.shadow_distance,20,100); result.exposure=clampf(result.exposure,.5,2.0); result.preset=clampi(result.preset,-1,3)
	return result
func startup():
	apply(data,loaded)
func helper(arguments: PackedStringArray) -> Dictionary:
	var output: Array=[]
	var path:=ProjectSettings.globalize_path("res://tools/DisplayModes.exe")
	if OS.get_name()!="Windows" or not FileAccess.file_exists(path): return {"ok":false,"text":""}
	var code:=OS.execute(path,arguments,output,true,false)
	return {"ok":code==0,"text":"".join(output)}
func discover_displays():
	var result:=helper(["--list"])
	if not result.ok: return
	var parsed=JSON.parse_string(result.text)
	if not parsed is Array: return
	displays=parsed
	var position:=DisplayServer.screen_get_position(DisplayServer.window_get_current_screen())
	for display in displays:
		if int(display.x)==position.x and int(display.y)==position.y:
			if not active_device.is_empty() and active_device!=display.device:
				restore_display(); original_mode={}
			active_device=display.device
			if original_mode.is_empty(): original_mode={"device":display.device,"width":int(display.current.width),"height":int(display.current.height),"hz":int(display.current.hz)}
			return
func display_info() -> Dictionary:
	for display in displays:
		if display.device==active_device: return display
	return {}
func automatic_resolution(mode: int=2) -> Vector2i:
	var info:=display_info()
	if mode==1 and not original_mode.is_empty(): return Vector2i(original_mode.width,original_mode.height)
	if not info.is_empty():
		var preferred: Dictionary=info.get("native",info.current)
		if mode!=2 or info.modes.any(func(m): return int(m.width)==int(preferred.width) and int(m.height)==int(preferred.height)): return Vector2i(preferred.width,preferred.height)
		return Vector2i(info.current.width,info.current.height)
	if DisplayServer.get_name()!="headless": return DisplayServer.screen_get_size()
	return Vector2i(data.width,data.height)
func change_native(width: int,height: int,hz: int) -> bool:
	if dry_run: return true
	var result:=helper(["--apply",active_device,str(width),str(height),str(hz)])
	display_changed=result.ok
	return result.ok
func restore_display():
	if not display_changed or original_mode.is_empty(): return
	helper(["--apply",original_mode.device,str(original_mode.width),str(original_mode.height),str(original_mode.hz)])
	display_changed=false
func apply(values: Dictionary,video: bool=true) -> bool:
	last_error=""; var proposed:=sanitize(values)
	if video and not dry_run:
		if not apply_display(proposed): return false
	data=proposed
	TranslationServer.set_locale(data.language)
	Engine.max_fps=data.fps
	if not dry_run: DisplayServer.window_set_vsync_mode(data.vsync)
	var viewport=get_viewport()
	viewport.scaling_3d_scale=data.scale; viewport.msaa_3d=data.aa; viewport.use_taa=data.taa
	viewport.scaling_3d_mode=data.scaling_mode
	viewport.anisotropic_filtering_level=data.anisotropy
	RenderingServer.directional_shadow_atlas_set_size([512,1024,4096,8192][data.shadows],true)
	apply_scene(game)
	Textures.apply(data.textures)
	return true
func apply_display(values: Dictionary) -> bool:
	var window=get_window()
	var resolution:=automatic_resolution(values.mode) if values.native_resolution else Vector2i(values.width,values.height)
	# Leave the previous exclusive mode before switching display timings.
	window.mode=Window.MODE_WINDOWED
	restore_display()
	if values.mode==2:
		var info:=display_info()
		if info.is_empty(): last_error="Modalità video non disponibile su questo display."; return false
		var hz: int=int(info.current.hz) if values.hz==0 else values.hz
		if values.native_resolution and not info.modes.any(func(m): return int(m.width)==resolution.x and int(m.height)==resolution.y and int(m.hz)==hz):
			var rates: Array=[]
			for mode in info.modes:
				if int(mode.width)==resolution.x and int(mode.height)==resolution.y: rates.append(int(mode.hz))
			if not rates.is_empty():
				rates.sort(); var requested:=hz; hz=rates[0]
				for rate in rates:
					if rate<=requested: hz=rate
		if not change_native(resolution.x,resolution.y,hz):
			last_error="Risoluzione o frequenza non supportata. Ripristinate le impostazioni precedenti."
			return false
		window.size=resolution; window.mode=Window.MODE_EXCLUSIVE_FULLSCREEN
	elif values.mode==1: window.mode=Window.MODE_FULLSCREEN
	else:
		window.size=resolution
		var rect:=DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		window.position=rect.position+(rect.size-window.size)/2
		if values.native_resolution: window.mode=Window.MODE_MAXIMIZED
	return true
func apply_scene(node: Node):
	if node==null: return
	if node is WorldEnvironment and node.environment:
		node.environment.ssao_enabled=data.ssao; node.environment.glow_enabled=data.glow
		node.environment.ssil_enabled=data.ssil; node.environment.ssr_enabled=data.ssr; node.environment.tonemap_exposure=data.exposure
	if node is DirectionalLight3D: node.shadow_enabled=data.shadows>0; node.directional_shadow_max_distance=data.shadow_distance
	if node is MultiMeshInstance3D and node.has_meta("spectators"):
		node.multimesh.visible_instance_count=roundi(node.multimesh.instance_count*[.35,.65,1.0][data.crowd])
	for child in node.get_children(): apply_scene(child)
func _notification(what: int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and not dry_run: restore_display()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN and not dry_run and data.mode==2 and not display_changed and not original_mode.is_empty():
		var resolution:=automatic_resolution(2) if data.native_resolution else Vector2i(data.width,data.height)
		change_native(resolution.x,resolution.y,int(original_mode.hz) if data.hz==0 else data.hz)
func _exit_tree():
	restore_display()
	if translation: TranslationServer.remove_translation(translation)
	if italian_translation: TranslationServer.remove_translation(italian_translation)
