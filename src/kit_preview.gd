extends PanelContainer
## Static native-rendered garment previews: no extra live 3D rigs in the menus.
var image: TextureRect
var caption: Label
static var cache: Dictionary={}
func _ready() -> void:
	var style:=StyleBoxFlat.new(); style.bg_color=Color("30435e"); style.border_color=Color("a7864b")
	style.set_border_width_all(1); style.set_corner_radius_all(8); add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new(); add_child(column)
	image=TextureRect.new(); image.custom_minimum_size=Vector2(240,155)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; column.add_child(image)
	caption=Label.new(); caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; caption.add_theme_font_size_override("font_size",13); column.add_child(caption)
func show_kit(club: String, variant: String) -> void:
	var path: String="res://assets/ui/kits46/"+club+"-"+variant+".png"
	if not cache.has(path):
		var source:=Image.load_from_file(path)
		if source!=null: source.generate_mipmaps(); cache[path]=ImageTexture.create_from_image(source)
	image.texture=cache.get(path)
	caption.text=("CASA" if variant=="home" else "TRASFERTA")+"  /  FRONTE E RETRO"
