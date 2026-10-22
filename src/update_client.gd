extends Node
signal changed(message: String)
signal versions_loaded(items: Array)
const REPOSITORY := "Vanic17/spike-forever"
var http: HTTPRequest
var releases: Array = []
var busy := false
var downloading := false
var selected: Dictionary = {}
var page := 1
var package_path := ""

static func compare_versions(candidate: String, installed: String) -> int:
	var a:=candidate.trim_prefix("v").split(".")
	var b:=installed.trim_prefix("v").split(".")
	if a.size()!=3 or b.size()!=3: return -1
	for part in a+b:
		if not part.is_valid_int() or int(part)<0: return -1
	for i in 3:
		if int(a[i])!=int(b[i]): return 1 if int(a[i])>int(b[i]) else -1
	return 0

static func newer_release(versions: Array, installed: String) -> Dictionary:
	var newest: Dictionary={}
	for release in versions:
		if release.get("draft",false) or release.get("prerelease",false): continue
		var tag: String=release.get("tag_name","")
		if compare_versions(tag,installed)<=0: continue
		var asset:=package_asset(release)
		if not String(asset.get("digest","")).begins_with("sha256:") or String(asset.get("digest","")).length()!=71: continue
		if not String(asset.get("browser_download_url","")).begins_with("https://github.com/"+REPOSITORY+"/releases/download/"): continue
		if newest.is_empty() or compare_versions(tag,newest.tag_name)>0: newest=release
	return newest

func _ready() -> void:
	http=HTTPRequest.new()
	http.timeout=30
	add_child(http)
	http.request_completed.connect(completed)

func check() -> void:
	if busy: return
	busy=true
	releases.clear()
	page=1
	fetch_page()

func fetch_page() -> void:
	changed.emit("Ricerca versioni pubblicate…")
	var error:=http.request("https://api.github.com/repos/"+REPOSITORY+"/releases?per_page=100&page="+str(page),["Accept: application/vnd.github+json","User-Agent: Spike-Forever-Updater"])
	if error!=OK: fail("Impossibile avviare la connessione: "+error_string(error))

static func package_asset(release: Dictionary) -> Dictionary:
	for asset in release.get("assets",[]):
		if asset.get("name","")=="SpikeForever-Windows.zip": return asset
	return {}

func install(release: Dictionary) -> void:
	if busy: return
	var probe_path:=ProjectSettings.globalize_path("res://.update-write-test")
	var probe:=FileAccess.open(probe_path,FileAccess.WRITE)
	if probe==null:
		fail("La cartella del gioco non è scrivibile. Spostala in una cartella personale prima di aggiornare.")
		return
	probe.close()
	DirAccess.remove_absolute(probe_path)
	selected=package_asset(release)
	var url: String=selected.get("browser_download_url","")
	var digest: String=selected.get("digest","")
	if not url.begins_with("https://github.com/"+REPOSITORY+"/releases/download/") or not digest.begins_with("sha256:") or digest.length()!=71:
		fail("Questa versione non contiene un pacchetto Windows verificabile.")
		return
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("updates"))
	package_path=OS.get_user_data_dir().path_join("updates/package.zip")
	http.download_file=package_path
	http.timeout=300
	busy=true
	downloading=true
	changed.emit("Download in corso. La versione attuale resta disponibile fino alla verifica.")
	var error:=http.request(url,["User-Agent: Spike-Forever-Updater"])
	if error!=OK: fail("Download non avviato: "+error_string(error))

func completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200:
		fail("Nessuna release disponibile: repository non pubblicata o connessione non riuscita." if code==404 else "Connessione non riuscita (HTTP "+str(code)+"). Riprova più tardi.")
		return
	if downloading:
		if FileAccess.get_sha256(package_path)!=String(selected.digest).trim_prefix("sha256:").to_lower():
			fail("Verifica del download fallita: aggiornamento annullato.")
			return
		var script:=ProjectSettings.globalize_path("res://tools/Install-Update.ps1")
		var args:=PackedStringArray(["-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File",script,"-Archive",package_path,"-Destination",ProjectSettings.globalize_path("res://"),"-ExpectedHash",String(selected.digest).trim_prefix("sha256:"),"-WaitPid",str(OS.get_process_id())])
		if OS.create_process("powershell.exe",args)<0:
			fail("Impossibile avviare l'installazione. Nessun file modificato.")
			return
		changed.emit("Pacchetto verificato. Chiusura e installazione; il gioco verrà riavviato.")
		get_tree().quit()
		return
	var parsed=JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array:
		fail("Risposta delle versioni non valida.")
		return
	for release in parsed:
		if release is Dictionary and not release.get("draft",true) and not release.get("prerelease",true) and not package_asset(release).is_empty(): releases.append(release)
	if parsed.size()==100:
		page+=1
		fetch_page()
		return
	busy=false
	versions_loaded.emit(releases)
	changed.emit("Nessuna patch pubblicata: la cronologia inizierà dalla prima release." if releases.is_empty() else "Seleziona la versione più recente oppure una precedente, poi premi Installa.")

func fail(message: String) -> void:
	busy=false
	downloading=false
	http.download_file=""
	http.timeout=30
	changed.emit(message)
