extends SceneTree
## Run after publication. Exercises the actual GDScript -> hidden PowerShell ->
## GitHub/CDN route. The worker can prepare a ZIP but NEVER installs it here.
var worker
var http: HTTPRequest
var updates:=0
var finished:=false
var result: Dictionary={}
func _initialize(): call_deferred("run")
func run():
	Engine.max_fps=30
	http=HTTPRequest.new();http.use_threads=true;http.timeout=45;root.add_child(http)
	http.request_completed.connect(metadata)
	http.request("https://api.github.com/repos/Vanic17/spike-forever/releases/latest",["User-Agent: Spike-Forever-Updater"])
	create_timer(180).timeout.connect(func():finish(false,"Timed out"))
func metadata(status: int,code: int,_headers: PackedStringArray,body: PackedByteArray):
	if status!=HTTPRequest.RESULT_SUCCESS or code!=200: finish(false,"Metadata connection failed");return
	var release=JSON.parse_string(body.get_string_from_utf8())
	var expected: String="v"+str(JSON.parse_string(FileAccess.get_file_as_string("res://version.json")).version)
	if release.get("tag_name","")!=expected: finish(false,"Latest release differs from installed test version");return
	var api=preload("res://src/update_client.gd")
	var index: Dictionary=api.index_asset(release);var archive: Dictionary=api.package_asset(release)
	result={"tag":release.tag_name,"index_digest":index.get("digest",""),"archive_digest":archive.get("digest",""),"installed":false}
	worker=preload("res://src/selective_update.gd").new();root.add_child(worker)
	worker.status.connect(func(message):print("SELECTIVE LIVE76 ",message))
	worker.progress.connect(func(_received,_total):updates+=1)
	worker.current.connect(func():finish(true,"current"))
	worker.prepared.connect(func(path,digest):
		result["prepared_bytes"]=FileAccess.get_file_as_bytes(path).size();result["prepared_sha256"]=digest
		finish(true,"prepared-only"))
	worker.failed.connect(func(message):finish(false,message))
	worker.fallback.connect(func(message):finish(false,"Unexpected full fallback: "+message))
	if not worker.start(index,archive):finish(false,"Could not start actual worker")
func finish(passed: bool,message: String):
	if finished:return
	finished=true;result.merge({"pass":passed,"result":message,"progress_events":updates})
	FileAccess.open("res://docs/selective76-live-client.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("SELECTIVE LIVE76 ",JSON.stringify(result));quit(0 if passed else 1)
