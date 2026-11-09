extends RefCounted
## One-off, field-limited correction. Never opens career/championship saves.
const MARKER="user://dominant-hand103-applied.json"
const BACKUP="user://roster-overrides.before-hand103.json"
static func apply(overrides: Dictionary,path: String) -> Error:
	if FileAccess.file_exists(MARKER):return OK
	if FileAccess.file_exists(path) and not JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary:return ERR_INVALID_DATA
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/dominant_hand103.json"))
	if not data is Dictionary or data.get("id")!="dominant-hand-103-once":return ERR_INVALID_DATA
	var updated: Dictionary=overrides.duplicate(true)
	for id in data.players:
		var fact: Dictionary=data.players[id]
		if fact.get("dominant_hand") not in ["left","right"]:return ERR_INVALID_DATA
		if not updated.has(id):updated[id]={}
		if not updated[id] is Dictionary:return ERR_INVALID_DATA
		updated[id].dominant_hand=fact.dominant_hand
	if FileAccess.file_exists(path) and not FileAccess.file_exists(BACKUP):
		var err:=DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(BACKUP))
		if err!=OK:return err
	var file:=FileAccess.open(path+".hand103.tmp",FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify(updated,"\t"));file.flush();file.close()
	var err:=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".hand103.tmp"),ProjectSettings.globalize_path(path))
	if err!=OK:return err
	overrides.clear();overrides.merge(updated,true)
	file=FileAccess.open(MARKER,FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"id":data.id,"applied":true}));file.close()
	return OK
