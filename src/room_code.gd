extends RefCounted
## Self-contained invitation, not a directory/relay or encryption of the IP.
## Version + IPv4 + port + 24-bit room generation + CRC16; Crockford Base32.
const ALPHABET="0123456789ABCDEFGHJKMNPQRSTVWXYZ"
static func valid_ipv4(value: String) -> bool:
	var parts=value.split(".")
	if parts.size()!=4:return false
	for part in parts:
		if part.is_empty() or not part.is_valid_int() or str(int(part))!=part or int(part)<0 or int(part)>255:return false
	return value!="0.0.0.0" and int(parts[0])<224

static func checksum(data: PackedByteArray) -> int:
	var crc: int=0xffff
	for byte in data:
		crc^=int(byte)<<8
		for bit in range(8):crc=((crc<<1)^0x1021 if crc&0x8000 else crc<<1)&0xffff
	return crc

static func encode(ip: String, port: int, room: int) -> String:
	if not valid_ipv4(ip) or port<1 or port>65535 or room<1 or room>0xffffff:return ""
	var bytes:=PackedByteArray([1])
	for part in ip.split("."):bytes.append(int(part))
	bytes.append(port>>8);bytes.append(port&255)
	bytes.append((room>>16)&255);bytes.append((room>>8)&255);bytes.append(room&255)
	var crc: int=checksum(bytes);bytes.append(crc>>8);bytes.append(crc&255)
	var buffer: int=0
	var bits: int=0
	var encoded: String=""
	for byte in bytes:
		buffer=(buffer<<8)|int(byte);bits+=8
		while bits>=5:
			bits-=5;encoded+=ALPHABET[(buffer>>bits)&31]
		buffer&=(1<<bits)-1
	if bits>0:encoded+=ALPHABET[(buffer<<(5-bits))&31]
	var code: String="SF"
	for i in range(0,encoded.length(),5):code+="-"+encoded.substr(i,5)
	return code

static func decode(code: String) -> Dictionary:
	if code.length()>64:return {}
	var value: String=code.strip_edges().to_upper().replace("-","").replace(" ","").replace("\n","").replace("\r","")
	if not value.begins_with("SF") or value.length()!=22:return {}
	value=value.substr(2).replace("O","0").replace("I","1").replace("L","1")
	var bytes:=PackedByteArray()
	var buffer: int=0
	var bits: int=0
	for letter in value:
		var index: int=ALPHABET.find(letter)
		if index<0:return {}
		buffer=(buffer<<5)|index;bits+=5
		if bits>=8:
			bits-=8;bytes.append((buffer>>bits)&255)
		buffer&=(1<<bits)-1
	if bytes.size()!=12 or buffer!=0 or bytes[0]!=1:return {}
	if checksum(bytes.slice(0,10))!=((int(bytes[10])<<8)|int(bytes[11])):return {}
	var ip: String="%d.%d.%d.%d"%[bytes[1],bytes[2],bytes[3],bytes[4]]
	var port: int=(int(bytes[5])<<8)|int(bytes[6])
	var room: int=(int(bytes[7])<<16)|(int(bytes[8])<<8)|int(bytes[9])
	if not valid_ipv4(ip) or port==0 or room==0:return {}
	return {"host":ip,"port":port,"room":room}
