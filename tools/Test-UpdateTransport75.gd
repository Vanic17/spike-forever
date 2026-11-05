extends SceneTree
var request: HTTPRequest
var stage:=0
var report: Dictionary={}
func _initialize(): call_deferred("run")
func run():
	request=HTTPRequest.new(); request.use_threads=true; request.timeout=60
	root.add_child(request); request.request_completed.connect(completed)
	request.request("https://api.github.com/repos/Vanic17/spike-forever/releases/latest",["User-Agent: Spike-Forever-Updater","Accept: application/vnd.github+json"])
	create_timer(120).timeout.connect(func(): push_error("Transport timeout"); quit(1))
func completed(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray):
	if result!=HTTPRequest.RESULT_SUCCESS or code not in [200,206]:
		push_error("Live transport failed: "+preload("res://src/update_client.gd").request_error(result,code)); quit(1); return
	if stage==0:
		var release=JSON.parse_string(body.get_string_from_utf8())
		var asset: Dictionary=preload("res://src/update_client.gd").package_asset(release)
		assert(not asset.is_empty() and str(asset.digest).begins_with("sha256:"))
		report={"release":release.tag_name,"asset_size":asset.size,"asset_digest":asset.digest,"api_http":code,"transport":"Godot HTTPRequest with Windows CA validation and CDN redirects"}
		stage=1
		request.request(asset.browser_download_url,["User-Agent: Spike-Forever-Updater","Range: bytes=0-65535"])
	else:
		assert(code==206 and body.size()==65536)
		report.merge({"pass":true,"download_http":code,"downloaded_range_bytes":body.size(),"installed":false})
		FileAccess.open("res://docs/update75-godot-transport.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("LIVE GODOT TRANSPORT75 PASS ",JSON.stringify(report)); quit()
