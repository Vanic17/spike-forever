extends SceneTree
class Client extends "res://src/update_client.gd":
	var full_downloads:=0
	var installs: Array=[]
	func download_full() -> void: full_downloads+=1
	func install_package(digest: String) -> void: installs.append({"path":package_path,"digest":digest})
var errors: Array[String]=[]
var events: Array=[]
func check(ok: bool,label: String):
	if not ok: errors.append(label); push_error(label)
func _initialize(): call_deferred("run")
func run():
	var client:=Client.new(); root.add_child(client)
	var reader=client.selective; reader.set_process(false)
	reader.folder=ProjectSettings.globalize_path("res://.runtime/selective76-ui")
	DirAccess.make_dir_recursive_absolute(reader.folder)
	client.download_progress.connect(func(received,total): events.append([received,total]))
	var failed: Array=[];reader.failed.connect(func(message): failed.append(message))
	var data:=FileAccess.open(reader.folder.path_join("selective.zip"),FileAccess.WRITE);data.store_string("verified-fixture");data.close()
	var digest:=FileAccess.get_sha256(reader.folder.path_join("selective.zip"))
	for state in [{"status":"scan","message":"Scansione","scanned":17,"files":100,"received":0,"total":0},{"status":"download","message":"Download","received":3,"total":10},{"status":"ready","message":"Pronto","received":10,"total":10,"package":reader.folder.path_join("selective.zip").replace("/","\\"),"sha256":digest}]:
		FileAccess.open(reader.folder.path_join("state.json"),FileAccess.WRITE).store_string(JSON.stringify(state))
		reader.running=true; reader._process(.2)
	check(events.size()==3 and events[1]==[3,10],"scan/download byte progress")
	check(client.installs.size()==1 and client.installs[0].digest==digest,"verified selective archive reaches normal installer")
	check(not reader.running and failed.is_empty(),"worker stops after ready; Windows path normalization")
	client.busy=true;client.downloading=true
	FileAccess.open(reader.folder.path_join("state.json"),FileAccess.WRITE).store_string('{"status":"current","message":"Corrente"}')
	reader.running=true;reader._process(.2)
	check(not client.busy and not client.downloading,"up-to-date clears busy state")
	FileAccess.open(reader.folder.path_join("state.json"),FileAccess.WRITE).store_string('{"status":"fallback","message":"Range unavailable"}')
	reader.running=true;reader._process(.2)
	check(client.full_downloads==1,"unsupported range safely falls back to full download")
	FileAccess.open(reader.folder.path_join("state.json"),FileAccess.WRITE).store_string(JSON.stringify({"status":"ready","package":reader.folder.path_join("selective.zip"),"sha256":"a".repeat(64)}))
	reader.running=true;reader._process(.2)
	check(failed.size()==1 and client.installs.size()==1,"wrong partial archive digest cannot install")
	check(not reader.start({},{}),"invalid release metadata cannot start helper")
	client.busy=false
	client.install({"assets":[{"name":"SpikeForever-Windows.zip","browser_download_url":"https://github.com/Vanic17/spike-forever/releases/download/v0.75.0/SpikeForever-Windows.zip","digest":"sha256:"+"b".repeat(64)}]})
	check(client.full_downloads==2,"older releases without index retain full installer")
	FileAccess.open("res://docs/selective76-ui.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":errors.is_empty(),"progress_events":events,"fallbacks":client.full_downloads,"verified_installs":client.installs.size(),"failures":errors},"  "))
	print("SELECTIVE UI76 ","PASS" if errors.is_empty() else "FAIL",errors);client.free();quit(0 if errors.is_empty() else 1)
