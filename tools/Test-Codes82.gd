extends SceneTree
const Code=preload("res://src/room_code.gd")
func _initialize():
	var rows: Array=[]
	for ip in ["127.0.0.1","192.168.1.250","83.27.211.98"]:
		for room in [1,0x123456,0xffffff]:
			var code:=Code.encode(ip,26761,room);var short:=Code.display(code)
			assert(short.length()==13)
			for variant in [code,short,short.to_lower(),"  "+short.substr(0,6)+" "+short.substr(6)+"\n"]:
				assert(Code.decode(variant)=={"host":ip,"port":26761,"room":room})
			var corrupt:=short.left(12)+("2" if short.right(1)!="2" else "4")
			assert(Code.decode(corrupt).is_empty())
			assert(Code.decode(Code.encode_legacy(ip,26761,room)).host==ip)
			assert(Code.decode(Code.encode(ip,26778,room)).port==26778)
			rows.append({"code":code,"typed_characters":short.length()})
	for invalid in ["","ABC","SF2-AAAAAAAAAAAAA","SF2-!!!!!!!!!!!!!!!!!!!!!"]:assert(Code.decode(invalid).is_empty())
	FileAccess.open("res://docs/online82-codes.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"cases":rows,"note":"Self-contained IPv4 invite, no directory/relay and no change to NAT requirements"},"  "))
	print("CODES82 PASS");quit()
