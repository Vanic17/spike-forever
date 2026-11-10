extends RefCounted
const PATH="user://online_connections108.cfg"
const Code=preload("res://src/room_code.gd")
var generation:=0
var recent: Array=[]
func _init() -> void:
	var c:=ConfigFile.new()
	if c.load(PATH)!=OK:return
	generation=clampi(int(c.get_value("host","generation",0)),0,0xffffff)
	var entries=c.get_value("recent","rooms",[])
	if entries is Array:
		for entry in entries:
			if entry is Dictionary and not Code.decode(str(entry.get("code",""))).is_empty() and recent.size()<8:recent.append(entry)
func save() -> Error:
	var c:=ConfigFile.new()
	if generation==0 and c.load(PATH)==OK:generation=clampi(int(c.get_value("host","generation",0)),0,0xffffff)
	c.set_value("host","generation",generation);c.set_value("recent","rooms",recent)
	var error:=c.save(PATH+".tmp")
	if error!=OK:return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH))
func host_id() -> int:
	if generation==0:generation=randi_range(1,0xffffff);save()
	return generation
func remember(code: String,label: String="") -> void:
	var endpoint:=Code.decode(code)
	if endpoint.is_empty():return
	var normalized:=Code.encode(endpoint.host,endpoint.port,endpoint.room)
	var old: Array=recent.filter(func(p):return p.code==normalized)
	var title: String=label if not label.is_empty() else (str(old[0].get("label","Stanza salvata")) if not old.is_empty() else "Stanza salvata")
	recent=recent.filter(func(p):return p.code!=normalized)
	recent.push_front({"code":normalized,"label":title,"last_join":Time.get_unix_time_from_system()})
	if recent.size()>8:recent.resize(8)
	save()
