extends RefCounted
## Separate, checksummed repository for the single-player career.
const SCHEMA:=1
const FOLDER:="user://legend72"
var error:=""
var recovered_backup:=false
var metadata: Dictionary={}
var suspended:=false

func path(slot: int) -> String:
	return FOLDER+"/legend-%02d.json"%clampi(slot,1,12)

func write(slot: int,state: Dictionary) -> bool:
	if suspended: return true
	if state.get("mode","")!="legend72" or not state.get("profile") is Dictionary:
		error="Salvataggio Diventa un mito non valido."; return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))!=OK:
		error="Impossibile creare la cartella Diventa un mito."; return false
	var target:=path(slot); var temporary:=target+".tmp"
	var payload:=JSON.stringify(state)
	var envelope={"schema":SCHEMA,"mode":"legend72","checksum":payload.sha256_text(),"payload":payload,"saved_at":Time.get_datetime_string_from_system(),"saved_at_unix":Time.get_unix_time_from_system()}
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: error="Impossibile scrivere Diventa un mito: "+error_string(FileAccess.get_open_error()); return false
	file.store_string(JSON.stringify(envelope)); file.flush(); file.close()
	if FileAccess.file_exists(target):
		var copied:=DirAccess.copy_absolute(ProjectSettings.globalize_path(target),ProjectSettings.globalize_path(target+".bak"))
		if copied!=OK: error="Backup Diventa un mito non riuscito: "+error_string(copied); return false
	var renamed:=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(target))
	if renamed!=OK: error="Salvataggio Diventa un mito non riuscito: "+error_string(renamed); return false
	error=""; return true

func decode(target: String) -> Dictionary:
	if not FileAccess.file_exists(target): return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(target))!=OK: return {}
	var wrapper=parser.data
	if not wrapper is Dictionary or wrapper.get("mode","")!="legend72" or not wrapper.get("payload") is String: return {}
	if int(wrapper.get("schema",0))>SCHEMA: error="Salvataggio di una versione più recente."; return {}
	if str(wrapper.get("checksum",""))!=str(wrapper.payload).sha256_text(): return {}
	if parser.parse(wrapper.payload)!=OK: return {}
	var value=parser.data
	if not value is Dictionary or value.get("mode","")!="legend72" or not value.get("profile") is Dictionary or not value.get("fixtures") is Array: return {}
	metadata[target]={"saved_at":str(wrapper.get("saved_at","")),"saved_at_unix":float(wrapper.get("saved_at_unix",FileAccess.get_modified_time(target)))}
	return value

func read(slot: int) -> Dictionary:
	error=""; recovered_backup=false
	var value:=decode(path(slot))
	if not value.is_empty(): return value
	value=decode(path(slot)+".bak")
	if not value.is_empty(): recovered_backup=true; return value
	if error.is_empty(): error="Carriera Diventa un mito mancante o danneggiata; nessun backup valido."
	return {}

func list_saves() -> Array:
	var rows: Array=[]
	for slot in range(1,13):
		var primary:=path(slot); var value:=decode(primary); var backup:=false
		if value.is_empty(): value=decode(primary+".bak"); backup=not value.is_empty()
		if value.is_empty(): continue
		var source: String=primary+".bak" if backup else primary
		var header: Dictionary=metadata.get(source,{})
		var modified: float=float(header.get("saved_at_unix",FileAccess.get_modified_time(source)))
		rows.append({"slot":slot,"mode":"legend72","club_id":value.club_id,"player_name":value.profile.get("name",""),"profile":value.profile.duplicate(true),"season":value.season,"season_label":value.get("season_label",str(value.season)),"date":value.date,"complete":value.get("complete",false),"backup":backup,"career_id":value.get("career_id",""),"saved_at":header.get("saved_at",Time.get_datetime_string_from_unix_time(int(modified))),"modified":modified})
	rows.sort_custom(func(a,b): return a.modified>b.modified if a.modified!=b.modified else a.slot>b.slot)
	return rows
