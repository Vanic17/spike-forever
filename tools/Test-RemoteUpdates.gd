extends SceneTree

var client
var finished := false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	client=load("res://src/update_client.gd").new()
	root.add_child(client)
	client.versions_loaded.connect(verify_versions)
	client.changed.connect(func(message): print("REMOTE UPDATE STATUS: ",message))
	client.check()
	await create_timer(45.0).timeout
	if not finished:
		push_error("Remote update discovery timed out or failed")
		quit(1)

func verify_versions(versions: Array) -> void:
	for entry in versions:
		if entry.get("tag_name","")!="v0.19.0": continue
		var asset=client.package_asset(entry)
		if asset.get("digest","")!="sha256:8fdafce1a024923679636117ada39ec044fdf0c42df9dd45d8d45db27dafc934":
			push_error("Published asset checksum differs from validated Windows package")
			quit(1)
			return
		finished=true
		print("REMOTE UPDATES PASS: live unauthenticated discovery / v0.19.0 / verified GitHub asset digest / ",versions.size()," release(s)")
		if "--download-package" in OS.get_cmdline_user_args():
			client.http.request_completed.disconnect(client.completed)
			DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("updates"))
			client.http.download_file=OS.get_user_data_dir().path_join("updates/remote-validation.zip")
			client.http.timeout=300
			client.http.request_completed.connect(verify_download)
			var error=client.http.request(asset.browser_download_url,["User-Agent: Spike-Forever-Updater"])
			if error!=OK:
				push_error("Download request could not start")
				quit(1)
		else:
			client.queue_free()
			call_deferred("quit")
		return
	push_error("Expected first release missing")
	quit(1)

func verify_download(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var path: String=client.http.download_file
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or FileAccess.get_sha256(path)!="8fdafce1a024923679636117ada39ec044fdf0c42df9dd45d8d45db27dafc934":
		push_error("Live Windows package download or checksum verification failed")
		quit(1)
		return
	FileAccess.open("res://docs/v19-remote-download-path.txt",FileAccess.WRITE).store_string(path)
	print("REMOTE PACKAGE PASS: unauthenticated HTTPRequest download / GitHub redirect / SHA-256 verified")
	client.queue_free()
	call_deferred("quit")
