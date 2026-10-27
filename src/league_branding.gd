extends RefCounted
static var manifest: Dictionary={}
static var textures: Dictionary={}
static var condensed: FontFile
static func data() -> Dictionary:
	if manifest.is_empty(): manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/branding/manifest.json"))
	return manifest
static func texture(path: String) -> Texture2D:
	if path.is_empty(): return null
	if not textures.has(path):
		var bitmap:=Image.load_from_file("res://"+path)
		if bitmap==null or bitmap.is_empty(): return null
		bitmap.generate_mipmaps(); textures[path]=ImageTexture.create_from_image(bitmap)
	return textures[path]
static func badge() -> Texture2D: return texture(data().superlega.path)
static func logo(club: String,white: bool=false) -> Texture2D:
	return texture(data().clubs.get(club,{}).get("white" if white else "color",""))
static func font() -> Font:
	if condensed==null:
		condensed=FontFile.new(); condensed.load_dynamic_font("res://assets/ui/BarlowCondensed-SemiBold.ttf")
	return condensed
static func emblem(parent: Node,club: String,width: float=64,height: float=54) -> TextureRect:
	var image:=TextureRect.new(); image.custom_minimum_size=Vector2(width,height)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE; image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.texture=logo(club,true); parent.add_child(image); return image
static func team(game,side: int) -> Dictionary:
	var kit: Dictionary=game.players[side*6].kit_identity
	var id: String=kit.get("_club_id","")
	return {"id":id,"abbreviation":data().clubs.get(id,{}).get("abbreviation",str(game.team_names[side]).left(3).to_upper()),"color":Color(kit.get("primary_hex_approx","#17458a" if side==0 else "#eeeeee"))}
static func fit_image(canvas: CanvasItem,tex: Texture2D,rect: Rect2,color: Color=Color.WHITE) -> void:
	if tex==null: return
	var fit:=tex.get_size()*minf(rect.size.x/tex.get_width(),rect.size.y/tex.get_height())
	canvas.draw_texture_rect(tex,Rect2(rect.get_center()-fit*.5,fit),false,color)
