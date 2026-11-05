extends Node
## The scan/hash/range download runs outside the render thread. This node only
## polls a small atomically written progress file; it never changes game files.
signal progress(received: int,total: int)
signal status(message: String)
signal prepared(path: String,digest: String)
signal fallback(message: String)
signal current
signal failed(message: String)
var running:=false
var folder:=""
var process_id:=-1
var elapsed:=0.0
var poll_elapsed:=0.0
var last_message:=""
func start(index: Dictionary,archive: Dictionary) -> bool:
	var script:=ProjectSettings.globalize_path("res://tools/Download-SelectiveUpdate.ps1")
	if not FileAccess.file_exists(script): return false
	if int(index.get("size",0))>16777216: return false
	for asset in [index,archive]:
		if not str(asset.get("browser_download_url","")).begins_with("https://github.com/Vanic17/spike-forever/releases/download/"): return false
		var digest: String=str(asset.get("digest","")).trim_prefix("sha256:")
		if not str(asset.get("digest","")).begins_with("sha256:") or digest.length()!=64 or not digest.is_valid_hex_number(false): return false
	folder=OS.get_user_data_dir().path_join("updates/scan-%d-%d"%[OS.get_process_id(),Time.get_ticks_usec()])
	if DirAccess.make_dir_recursive_absolute(folder)!=OK: return false
	var args:=PackedStringArray(["-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File",script,"-Destination",ProjectSettings.globalize_path("res://"),"-StateFolder",folder,"-IndexHash",str(index.digest).trim_prefix("sha256:"),"-ArchiveHash",str(archive.digest).trim_prefix("sha256:"),"-IndexUrl",index.browser_download_url,"-ArchiveUrl",archive.browser_download_url])
	process_id=OS.create_process("powershell.exe",args)
	if process_id<0: return false
	running=true; elapsed=0; poll_elapsed=0
	status.emit("Scansione dei file installati…")
	return true
func _process(dt: float) -> void:
	if not running: return
	elapsed+=dt; poll_elapsed+=dt
	if poll_elapsed<.1: return
	poll_elapsed=0
	var path:=folder.path_join("state.json")
	if FileAccess.file_exists(path):
		var state=JSON.parse_string(FileAccess.get_file_as_string(path))
		if state is Dictionary:
			var message: String=str(state.get("message",""))
			if state.get("status","")=="scan": message+=" · %d/%d"%[int(state.get("scanned",0)),int(state.get("files",0))]
			if state.get("status","")=="download": message="Aggiornamento selettivo · %d file modificati"%int(state.get("changed_files",0))
			if message!=last_message: status.emit(message); last_message=message
			progress.emit(int(state.get("received",0)),int(state.get("total",0)))
			match str(state.get("status","")):
				"ready":
					running=false
					var package: String=str(state.get("package","")); var digest: String=str(state.get("sha256",""))
					if package.replace("\\","/")!=folder.path_join("selective.zip").replace("\\","/") or digest.length()!=64 or FileAccess.get_sha256(package)!=digest:
						failed.emit("Pacchetto selettivo non verificabile. Nessun file del gioco modificato."); return
					prepared.emit(package,digest); return
				"current": running=false; current.emit(); return
				"fallback": running=false; fallback.emit(message); return
				"error": running=false; failed.emit(message); return
	if elapsed>5 and not OS.is_process_running(process_id):
		running=false; fallback.emit("Scansione non completata")
