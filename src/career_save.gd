extends RefCounted
## Versioned, checksummed user data. No career writes touch the base database.
const SCHEMA:=1
const FOLDER:="user://careers"
var error:=""
var recovered_backup:=false
var metadata: Dictionary={}
func path(slot: int) -> String: return FOLDER+"/career-%02d.json"%clampi(slot,1,12)
func write(slot: int,state: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	var target:=path(slot); var temporary:=target+".tmp"
	var payload:=JSON.stringify(state)
	var envelope={"schema":SCHEMA,"checksum":payload.sha256_text(),"payload":payload,"club_id":state.club_id,"season":state.season,"date":state.date,"saved_at":Time.get_datetime_string_from_system(),"saved_at_unix":Time.get_unix_time_from_system()}
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: error="Impossibile scrivere il salvataggio: "+error_string(FileAccess.get_open_error()); return false
	file.store_string(JSON.stringify(envelope)); file.flush(); file.close()
	if FileAccess.file_exists(target):
		var copied:=DirAccess.copy_absolute(ProjectSettings.globalize_path(target),ProjectSettings.globalize_path(target+".bak"))
		if copied!=OK: error="Backup non riuscito: "+error_string(copied); return false
	var renamed:=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(target))
	if renamed!=OK: error="Salvataggio atomico non riuscito: "+error_string(renamed); return false
	error=""; return true
func decode(target: String) -> Dictionary:
	if not FileAccess.file_exists(target): return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(target))!=OK: return {}
	var wrapped=parser.data
	if not wrapped is Dictionary or not wrapped.get("payload") is String: return {}
	if int(wrapped.get("schema",0))>SCHEMA: error="Salvataggio di una versione più recente."; return {}
	if str(wrapped.get("checksum",""))!=str(wrapped.payload).sha256_text(): return {}
	if parser.parse(wrapped.payload)!=OK: return {}
	var value=parser.data
	if not value is Dictionary or not value.has("fixtures") or not value.has("club_id"): return {}
	metadata[target]={"saved_at":str(wrapped.get("saved_at","")),"saved_at_unix":float(wrapped.get("saved_at_unix",FileAccess.get_modified_time(target)))}
	return value
func read(slot: int) -> Dictionary:
	error=""; recovered_backup=false
	var value:=decode(path(slot))
	if not value.is_empty(): return value
	value=decode(path(slot)+".bak")
	if not value.is_empty(): recovered_backup=true; return value
	if error.is_empty(): error="Salvataggio mancante o danneggiato; nessun backup valido."
	return {}
func list_saves() -> Array:
	var rows: Array=[]
	for slot in range(1,13):
		var primary:=path(slot); var value:=decode(primary)
		var backup:=false
		if value.is_empty(): value=decode(primary+".bak"); backup=not value.is_empty()
		if value.is_empty(): continue
		var source: String=primary+".bak" if backup else primary
		var header: Dictionary=metadata.get(source,{})
		var modified: float=header.get("saved_at_unix",float(FileAccess.get_modified_time(source)))
		rows.append({"slot":slot,"club_id":value.club_id,"season":value.season,"season_label":value.get("season_label",str(value.season)),"date":value.date,"complete":value.get("complete",false),"backup":backup,"career_id":value.get("career_id",""),"saved_at":header.get("saved_at",Time.get_datetime_string_from_unix_time(int(modified))),"modified":modified})
	rows.sort_custom(func(a,b): return a.modified>b.modified if a.modified!=b.modified else a.slot>b.slot)
	return rows
