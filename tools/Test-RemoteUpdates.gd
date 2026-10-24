extends SceneTree

var client
var finished := false
var expected_hash := ""
var expected_tag := ""
var published_hash := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	expected_tag="v"+str(JSON.parse_string(FileAccess.get_file_as_string("res://version.json")).version)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expected-hash="): expected_hash=arg.trim_prefix("--expected-hash=").to_lower()
	client=load("res://src/update_client.gd").new()
	root.add_child(client)
	client.versions_loaded.connect(verify_versions)
	client.changed.connect(func(message): print("REMOTE UPDATE STATUS: ",message))
	client.check()
	create_timer(45.0).timeout.connect(func():
		if not finished:
			push_error("Remote update discovery timed out or failed")
			quit(1))

func verify_versions(versions: Array) -> void:
	for entry in versions:
		if entry.get("tag_name","")!=expected_tag: continue
		var asset=client.package_asset(entry)
		published_hash=String(asset.get("digest","")).trim_prefix("sha256:")
		if published_hash.length()!=64 or (not expected_hash.is_empty() and published_hash!=expected_hash):
			push_error("Published asset checksum differs from validated Windows package")
			quit(1)
			return
		finished=true
		if expected_tag=="v0.20.0": assert(versions.any(func(old): return old.get("tag_name","")=="v0.19.0"),"Previous release must remain selectable")
		if expected_tag=="v0.21.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.20.0"),"Previous release must remain selectable")
			var offer=client.newer_release(versions,"0.20.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.20.0 -> ",offer.tag_name)
		if expected_tag=="v0.22.0":
			for previous in ["v0.19.0","v0.20.0","v0.21.0"]:
				assert(versions.any(func(old): return old.get("tag_name","")==previous),"Every previous release must remain selectable")
			var offer=client.newer_release(versions,"0.21.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.21.0 -> ",offer.tag_name)
		if expected_tag=="v0.23.0":
			for previous in ["v0.19.0","v0.20.0","v0.21.0","v0.22.0"]:
				assert(versions.any(func(old): return old.get("tag_name","")==previous),"Previous patches must remain selectable")
			var offer=client.newer_release(versions,"0.22.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.22.0 -> ",offer.tag_name)
		if expected_tag=="v0.24.0":
			for previous in ["v0.19.0","v0.20.0","v0.21.0","v0.22.0","v0.23.0"]:
				assert(versions.any(func(old): return old.get("tag_name","")==previous),"Previous patches must remain selectable")
			var offer=client.newer_release(versions,"0.23.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.23.0 -> ",offer.tag_name)
		if expected_tag=="v0.25.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.24.0"))
			assert(not client.newer_release(versions,"0.24.0").is_empty())
		if expected_tag=="v0.26.0":
			for previous in ["v0.19.0","v0.20.0","v0.21.0","v0.22.0","v0.23.0","v0.24.0","v0.25.0"]:
				assert(versions.any(func(old): return old.get("tag_name","")==previous),"Previous releases must remain selectable")
			var offer=client.newer_release(versions,"0.25.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
		if expected_tag=="v0.38.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.37.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.37.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0,"Startup must offer the new version to v0.37 users")
			print("LIVE STARTUP OFFER PASS: installed 0.37.0 -> ",offer.tag_name)
		if expected_tag=="v0.39.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.38.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.38.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0,"Startup must offer the new version to v0.38 users")
			print("LIVE STARTUP OFFER PASS: installed 0.38.0 -> ",offer.tag_name)
		if expected_tag=="v0.40.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.39.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.39.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.39.0 -> ",offer.tag_name)
		if expected_tag=="v0.41.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.40.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.40.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.40.0 -> ",offer.tag_name)
		if expected_tag=="v0.42.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.41.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.41.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.41.0 -> ",offer.tag_name)
		if expected_tag=="v0.43.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.42.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.42.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.42.0 -> ",offer.tag_name)
		if expected_tag=="v0.44.0":
			assert(versions.any(func(old): return old.get("tag_name","")=="v0.43.0"),"Previous patch must remain selectable")
			var offer=client.newer_release(versions,"0.43.0")
			assert(not offer.is_empty() and client.compare_versions(offer.tag_name,expected_tag)>=0)
			print("LIVE STARTUP OFFER PASS: installed 0.43.0 -> ",offer.tag_name)
		print("REMOTE UPDATES PASS: live unauthenticated discovery / ",expected_tag," / verified GitHub asset digest / ",versions.size()," release(s)")
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
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or FileAccess.get_sha256(path)!=published_hash:
		push_error("Live Windows package download or checksum verification failed")
		quit(1)
		return
	FileAccess.open("res://docs/remote-download-path.txt",FileAccess.WRITE).store_string(path)
	print("REMOTE PACKAGE PASS: unauthenticated HTTPRequest download / GitHub redirect / SHA-256 verified")
	client.queue_free()
	call_deferred("quit")
